package io.pentacoxian.gglp

import android.app.Activity
import android.content.Context
import androidx.test.ext.junit.runners.AndroidJUnit4
import androidx.test.platform.app.InstrumentationRegistry
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import org.json.JSONObject
import org.junit.After
import org.junit.Assert.*
import org.junit.Before
import org.junit.Test
import org.junit.runner.RunWith
import java.io.File
import java.nio.ByteBuffer
import java.security.MessageDigest
import java.util.concurrent.CountDownLatch
import java.util.concurrent.TimeUnit

/** Generate disposable APK fixtures with android/test/generate_update_fixtures.py first. */
@RunWith(AndroidJUnit4::class)
class UpdateInstallerTest {
    private lateinit var activity: Activity
    private lateinit var installer: UpdateInstaller
    private val instrumentation = InstrumentationRegistry.getInstrumentation()

    @Before fun setUp() {
        instrumentation.runOnMainSync {
            activity = HarnessActivity(instrumentation.targetContext)
            installer = UpdateInstaller(activity, FakeMessenger())
        }
        call("getInstalledApp") // Wait for cold-start cleanup on the worker.
    }

    @After fun tearDown() {
        installer.close()
        File(activity.cacheDir, "updates").deleteRecursively()
    }

    @Test fun validSignedApkIsVerifiedAndRestoredAcrossRestart() {
        val verified = call("verifyApk", stage("valid.apk")) as Map<*, *>
        val path = verified["path"] as String
        assertTrue(path.endsWith(".apk"))
        assertTrue(File(path).isFile)
        restartBridge()
        val restored = call("getPendingUpdate") as Map<*, *>
        assertEquals(path, restored["path"])
    }

    @Test fun cryptographicallyAlteredApkIsRejectedEvenWithMatchingChecksum() {
        // stage computes the hash from the already-tampered file.
        assertRejected(stage("tampered.apk"))
    }

    @Test fun wrongSigningKeyAndWrongPackageAreRejected() {
        assertRejected(stage("wrong-key.apk"))
        assertRejected(stage("wrong-package.apk"))
    }

    @Test fun actualEqualAndOlderApkVersionsAreRejected() {
        assertRejected(stage("equal.apk"))
        assertRejected(stage("older.apk"))
        val installed = call("getInstalledApp") as Map<*, *>
        val version = (installed["versionCode"] as Number).toLong()
        for (requested in listOf(version, version - 1)) {
            assertNotNull(invoke("prepareDownload", mapOf("versionCode" to requested)).error)
        }
    }

    @Test fun checksumTruncationAndPathTraversalAreRejected() {
        assertRejected(stage("valid.apk") + ("sha256" to "0".repeat(64)))
        val truncated = stage("valid.apk")
        File(truncated["path"] as String).appendBytes(byteArrayOf(0))
        assertRejected(truncated)
        assertRejected(stage("valid.apk") + ("path" to File(activity.cacheDir, "../outside.apk").path))
    }

    @Test fun partialDownloadsAreRemovedOnRestartAndExpiredCandidatesAreCleaned() {
        val partial = stage("valid.apk")["path"] as String
        restartBridge()
        assertNull(call("getPendingUpdate"))
        assertFalse(File(partial).exists())
        val verified = call("verifyApk", stage("valid.apk")) as Map<*, *>
        val path = verified["path"] as String
        val metadata = File(File(path).parentFile, "pending.json")
        val json = JSONObject(metadata.readText())
        json.put("verifiedAt", System.currentTimeMillis() - UpdatePolicy.MAX_AGE_MS - 1000)
        metadata.writeText(json.toString())
        call("cleanupDownloads")
        assertFalse(File(path).exists())
        assertNull(call("getPendingUpdate"))
    }

    @Test fun malformedArgumentsAndUnrecognizedMethodsFailSafely() {
        assertNotNull(invoke("verifyApk", emptyMap<String, Any>()).error)
        assertNotNull(invoke("prepareDownload", mapOf("versionCode" to 1.5)).error)
        assertEquals("not_implemented", invoke("missingMethod").error)
        assertTrue(call("canInstallPackages") is Boolean)
    }

    @Test fun expiredCandidateCannotBeInstalledWithoutPriorCleanup() {
        val verified = call("verifyApk", stage("valid.apk")) as Map<*, *>
        val path = verified["path"] as String
        val metadata = File(File(path).parentFile, "pending.json")
        val json = JSONObject(metadata.readText())
        json.put("verifiedAt", System.currentTimeMillis() - UpdatePolicy.MAX_AGE_MS - 1000)
        metadata.writeText(json.toString())
        assertNotNull(invoke("installApk", verified).error)
        assertFalse(File(path).exists())
    }

    private fun restartBridge() {
        installer.close()
        instrumentation.runOnMainSync { installer = UpdateInstaller(activity, FakeMessenger()) }
        call("getInstalledApp")
    }

    private fun stage(fixture: String): Map<String, Any> {
        val prepared = call("prepareDownload", mapOf("versionCode" to 1000000L)) as Map<*, *>
        val path = prepared["path"] as String
        instrumentation.context.assets.open(fixture).use { input ->
            File(path).outputStream().use { output -> input.copyTo(output) }
        }
        val file = File(path)
        return mapOf("path" to path, "packageId" to "io.pentacoxian.gglp",
            "versionCode" to 1000000L, "versionName" to "999.0.0", "size" to file.length(),
            "sha256" to MessageDigest.getInstance("SHA-256").digest(file.readBytes())
                .joinToString("") { "%02x".format(it) })
    }

    private fun assertRejected(arguments: Map<String, Any>) {
        assertNotNull("The unsafe update must be rejected", invoke("verifyApk", arguments).error)
    }

    private fun call(method: String, args: Any? = null): Any? {
        val result = invoke(method, args)
        assertNull("$method: ${result.message}", result.error)
        return result.value
    }

    private fun invoke(method: String, args: Any? = null): CapturedResult {
        val result = CapturedResult()
        instrumentation.runOnMainSync { installer.onMethodCall(MethodCall(method, args), result) }
        assertTrue("$method timed out", result.done.await(90, TimeUnit.SECONDS))
        return result
    }

    private class CapturedResult : MethodChannel.Result {
        val done = CountDownLatch(1)
        var value: Any? = null
        var error: String? = null
        var message: String? = null
        override fun success(result: Any?) { value = result; done.countDown() }
        override fun error(code: String, message: String?, details: Any?) {
            error = code; this.message = message; done.countDown()
        }
        override fun notImplemented() { error = "not_implemented"; done.countDown() }
    }

    private class FakeMessenger : BinaryMessenger {
        override fun send(channel: String, message: ByteBuffer?) { }
        override fun send(channel: String, message: ByteBuffer?, callback: BinaryMessenger.BinaryReply?) { }
        override fun setMessageHandler(channel: String, handler: BinaryMessenger.BinaryMessageHandler?) { }
    }

    // Exercise the production bridge against the real package manager and cache,
    // without booting a Flutter UI or making network requests during native tests.
    private class HarnessActivity(context: Context) : Activity() {
        init { attachBaseContext(context) }
    }
}
