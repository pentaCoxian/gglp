package io.pentacoxian.gglp

import android.app.Activity
import android.content.ActivityNotFoundException
import android.content.ClipData
import android.content.Intent
import android.content.pm.PackageInfo
import android.content.pm.PackageManager
import android.net.Uri
import android.os.Build
import android.os.Handler
import android.os.Looper
import android.provider.Settings
import androidx.core.content.FileProvider
import com.android.apksig.ApkVerifier
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import org.json.JSONObject
import java.io.Closeable
import java.io.File
import java.io.IOException
import java.security.MessageDigest
import java.util.concurrent.Executors

/** No networking or automatic installation: Dart requests each download and user action. */
internal class UpdateInstaller(
    private val activity: Activity,
    messenger: BinaryMessenger,
) : Closeable, MethodChannel.MethodCallHandler {
    private val channel = MethodChannel(messenger, "gglp/updates")
    private val worker = Executors.newSingleThreadExecutor()
    private val main = Handler(Looper.getMainLooper())
    private val directory = File(activity.cacheDir.canonicalFile, "updates")
    private val metadataFile = File(directory, "pending.json")
    private var activeDownload: File? = null
    @Volatile private var closed = false

    init {
        channel.setMethodCallHandler(this)
        worker.execute { runCatching { cleanupDownloads() } }
    }

    override fun close() {
        closed = true
        channel.setMethodCallHandler(null)
        worker.shutdown()
    }

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "canInstallPackages" -> result.success(canInstallPackages())
            "openInstallPermissionSettings" -> {
                try {
                    if (Build.VERSION.SDK_INT >= 26) {
                        activity.startActivity(Intent(
                            Settings.ACTION_MANAGE_UNKNOWN_APP_SOURCES,
                            Uri.parse("package:${activity.packageName}"),
                        ))
                    }
                    result.success(null)
                } catch (_: ActivityNotFoundException) {
                    result.error("unavailable", "Android install settings are unavailable.", null)
                } catch (_: SecurityException) {
                    result.error("unavailable", "Android blocked access to install settings.", null)
                }
            }
            "getInstalledApp", "prepareDownload", "verifyApk", "installApk",
            "cleanupDownloads", "getPendingUpdate" -> worker.execute {
                try {
                    val value: Any? = when (call.method) {
                        "getInstalledApp" -> installedApp().let {
                            mapOf("packageId" to it.packageName, "versionName" to it.versionName,
                                "versionCode" to versionCode(it), "sdkInt" to Build.VERSION.SDK_INT)
                        }
                        "prepareDownload" -> prepareDownload(number(call, "versionCode"))
                        "verifyApk", "installApk" -> verifyApk(request(call))
                        "getPendingUpdate" -> pendingUpdate()
                        else -> { cleanupDownloads(); null }
                    }
                    main.post {
                        if (!closed) {
                            if (call.method == "installApk") {
                                @Suppress("UNCHECKED_CAST")
                                launchInstaller(File((value as Map<String, Any>)["path"] as String), result)
                            } else result.success(value)
                        }
                    }
                } catch (error: Exception) {
                    main.post {
                        if (!closed) result.error(
                            when (error) {
                                is IllegalArgumentException -> "invalid_apk"
                                is IOException -> "io_error"
                                else -> "unavailable"
                            }, error.message ?: "The update could not be verified.", null,
                        )
                    }
                }
            }
            else -> result.notImplemented()
        }
    }

    private fun request(call: MethodCall): Candidate = Candidate(
        path = call.argument<String>("path") ?: throw IllegalArgumentException("Missing APK path."),
        packageId = call.argument<String>("packageId") ?: throw IllegalArgumentException("Missing package."),
        versionCode = number(call, "versionCode"),
        versionName = call.argument<String>("versionName") ?: throw IllegalArgumentException("Missing version."),
        size = number(call, "size"),
        sha256 = call.argument<String>("sha256") ?: throw IllegalArgumentException("Missing checksum."),
        verifiedAt = System.currentTimeMillis(),
    )

    private fun number(call: MethodCall, name: String): Long {
        val value = call.argument<Any>(name)
        require(value is Int || value is Long) { "Missing or invalid $name." }
        return (value as Number).toLong()
    }

    private fun canInstallPackages(): Boolean =
        Build.VERSION.SDK_INT < 26 || activity.packageManager.canRequestPackageInstalls()

    @Suppress("DEPRECATION")
    private fun installedApp(): PackageInfo = activity.packageManager.getPackageInfo(
        activity.packageName,
        if (Build.VERSION.SDK_INT >= 28) PackageManager.GET_SIGNING_CERTIFICATES
        else PackageManager.GET_SIGNATURES,
    )

    private fun prepareDownload(version: Long): Map<String, String> {
        require(version > versionCode(installedApp())) { "The update must be newer than the installed app." }
        check(directory.isDirectory || directory.mkdirs()) { "Cannot create the update cache." }
        directory.listFiles()?.forEach { check(it.delete()) { "Cannot clear the previous update." } }
        val file = File(directory, "update-$version.part")
        check(file.createNewFile()) { "Cannot create the update download." }
        activeDownload = file
        return mapOf("path" to file.absolutePath)
    }

    private fun candidateFile(path: String, version: Long): File {
        val file = File(path)
        require(file.isAbsolute && file.absoluteFile == file.canonicalFile &&
            file.parentFile == directory &&
            file.name in setOf("update-$version.part", "update-$version.apk")) {
            "The APK must be in this app's private update cache."
        }
        return file
    }

    @Suppress("DEPRECATION")
    private fun verifyApk(candidate: Candidate): Map<String, Any> {
        val installed = installedApp()
        UpdatePolicy.validateRequest(candidate.packageId, installed.packageName,
            candidate.versionCode, versionCode(installed), candidate.versionName,
            candidate.size, candidate.sha256)
        val file = candidateFile(candidate.path, candidate.versionCode)
        try {
            if (file.extension == "apk") {
                val saved = readMetadata()
                require(saved != null && saved.path == file.absolutePath &&
                    !UpdatePolicy.expired(saved.verifiedAt, System.currentTimeMillis())) {
                    "The cached update has expired. Please download it again."
                }
            }
            require(file.isFile && file.length() == candidate.size) { "The APK download is incomplete." }
            require(digest(file).equals(candidate.sha256, ignoreCase = true)) { "The APK checksum does not match." }

            // PackageManager can collect certificates without verifying APK contents.
            // Verify the actual signature and content digest before trusting its identity.
            val verified = ApkVerifier.Builder(file)
                .setMinCheckedPlatformVersion(Build.VERSION.SDK_INT)
                .setMaxCheckedPlatformVersion(Build.VERSION.SDK_INT)
                .build().verify()
            require(verified.isVerified) { "The APK signature is invalid." }
            val archive = activity.packageManager.getPackageArchiveInfo(file.path,
                if (Build.VERSION.SDK_INT >= 28) PackageManager.GET_SIGNING_CERTIFICATES
                else PackageManager.GET_SIGNATURES)
                ?: throw IllegalArgumentException("The APK cannot be read.")
            val currentCertificates = certificates(installed)
            val cryptographicCertificates = verified.signerCertificates.map { hex(it.encoded) }.toSet()
            require(cryptographicCertificates == currentCertificates) {
                "The APK was not signed with this app's current signing key."
            }
            UpdatePolicy.validateArchive(candidate.packageId, candidate.versionCode,
                candidate.versionName, archive.packageName, versionCode(archive),
                archive.versionName,
                if (Build.VERSION.SDK_INT >= 24) archive.applicationInfo?.minSdkVersion ?: 1 else 1,
                Build.VERSION.SDK_INT, currentCertificates, certificates(archive))

            val destination = File(directory, "update-${candidate.versionCode}.apk")
            if (file != destination) {
                require(!destination.exists()) { "An update is already cached." }
                check(file.renameTo(destination)) { "Cannot finish the update download." }
            }
            activeDownload = null
            val previous = readMetadata()
            val saved = candidate.copy(path = destination.absolutePath,
                verifiedAt = if (previous != null && previous.path == destination.absolutePath)
                    previous.verifiedAt else candidate.verifiedAt)
            writeMetadata(saved)
            return saved.toMap()
        } catch (error: Exception) {
            file.delete()
            if (activeDownload == file) activeDownload = null
            if (readMetadata()?.versionCode == candidate.versionCode) metadataFile.delete()
            throw error
        }
    }

    private fun launchInstaller(file: File, result: MethodChannel.Result) {
        if (!canInstallPackages()) {
            result.error("permission_required", "Allow GGLP to install apps before installing this update.", null)
            return
        }
        try {
            val uri = FileProvider.getUriForFile(activity, "${activity.packageName}.updates", file)
            val intent = Intent(Intent.ACTION_VIEW).apply {
                setDataAndType(uri, "application/vnd.android.package-archive")
                addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION)
                clipData = ClipData.newRawUri("GGLP update", uri)
            }
            activity.startActivity(intent)
            // A successful handoff is not a successful installation. Dart checks
            // the installed version when the app next enters the foreground.
            result.success(null)
        } catch (_: ActivityNotFoundException) {
            result.error("unavailable", "No Android package installer is available.", null)
        } catch (_: SecurityException) {
            result.error("unavailable", "Android blocked this installer request.", null)
        }
    }

    private fun cleanupDownloads() {
        if (!directory.exists()) return
        val pending = readMetadata()
        val keep = pending?.takeIf {
            !UpdatePolicy.expired(it.verifiedAt, System.currentTimeMillis()) &&
                it.versionCode > versionCode(installedApp()) &&
                runCatching { candidateFile(it.path, it.versionCode).isFile }.getOrDefault(false)
        }
        directory.listFiles()?.forEach { file ->
            if (file != activeDownload &&
                !(keep != null && (file.path == keep.path || file == metadataFile))) file.delete()
        }
    }

    private fun pendingUpdate(): Map<String, Any>? {
        cleanupDownloads()
        val candidate = readMetadata() ?: return null
        return runCatching { verifyApk(candidate) }.getOrElse {
            metadataFile.delete()
            cleanupDownloads()
            null
        }
    }

    private fun readMetadata(): Candidate? = runCatching {
        require(metadataFile.length() in 1..4096)
        val json = JSONObject(metadataFile.readText())
        Candidate(json.getString("path"), json.getString("packageId"),
            json.getLong("versionCode"), json.getString("versionName"),
            json.getLong("size"), json.getString("sha256"), json.getLong("verifiedAt"))
    }.getOrNull()

    private fun writeMetadata(candidate: Candidate) {
        val temporary = File(directory, "pending.tmp")
        temporary.writeText(JSONObject(candidate.toMap() + ("verifiedAt" to candidate.verifiedAt)).toString())
        check(temporary.renameTo(metadataFile)) { "Cannot save the verified update." }
    }

    private fun digest(file: File): String {
        val digest = MessageDigest.getInstance("SHA-256")
        file.inputStream().buffered().use { input ->
            val buffer = ByteArray(64 * 1024)
            var total = 0L
            while (true) {
                val read = input.read(buffer)
                if (read < 0) break
                total += read
                require(total <= UpdatePolicy.MAX_APK_BYTES) { "The APK is too large." }
                digest.update(buffer, 0, read)
            }
        }
        return hex(digest.digest())
    }

    @Suppress("DEPRECATION")
    private fun certificates(info: PackageInfo): Set<String> {
        val signatures = if (Build.VERSION.SDK_INT >= 28) info.signingInfo?.apkContentsSigners
            else info.signatures
        return signatures?.map { hex(it.toByteArray()) }?.toSet() ?: emptySet()
    }

    @Suppress("DEPRECATION")
    private fun versionCode(info: PackageInfo): Long =
        if (Build.VERSION.SDK_INT >= 28) info.longVersionCode else info.versionCode.toLong()

    private fun hex(bytes: ByteArray): String = bytes.joinToString("") { "%02x".format(it) }

    private data class Candidate(
        val path: String,
        val packageId: String,
        val versionCode: Long,
        val versionName: String,
        val size: Long,
        val sha256: String,
        val verifiedAt: Long,
    ) {
        fun toMap(): Map<String, Any> = mapOf("path" to path, "packageId" to packageId,
            "versionCode" to versionCode, "versionName" to versionName, "size" to size, "sha256" to sha256)
    }
}
