package io.pentacoxian.gglp

/** Checks shared by fresh downloads, restored downloads, and installation. */
internal object UpdatePolicy {
    const val MAX_APK_BYTES = 200L * 1024 * 1024
    const val MAX_AGE_MS = 7L * 24 * 60 * 60 * 1000

    fun validateRequest(
        packageId: String,
        installedPackage: String,
        versionCode: Long,
        installedVersion: Long,
        versionName: String,
        size: Long,
        sha256: String,
    ) {
        require(packageId == installedPackage) { "The update belongs to another app." }
        require(versionCode > installedVersion) { "The update must be newer than the installed app." }
        require(versionName.isNotBlank() && versionName.length <= 100) { "Invalid update version." }
        require(size in 1..MAX_APK_BYTES) { "The update has an unsupported size." }
        require(sha256.matches(Regex("[a-fA-F0-9]{64}"))) { "Invalid update checksum." }
    }

    fun validateArchive(
        expectedPackage: String,
        expectedVersion: Long,
        expectedVersionName: String,
        actualPackage: String?,
        actualVersion: Long,
        actualVersionName: String?,
        minSdk: Int,
        deviceSdk: Int,
        installedCertificates: Set<String>,
        archiveCertificates: Set<String>,
    ) {
        require(actualPackage == expectedPackage) { "The APK belongs to another app." }
        require(actualVersion == expectedVersion && actualVersionName == expectedVersionName) {
            "The APK version does not match the release."
        }
        require(minSdk <= deviceSdk) { "This update needs a newer Android version." }
        require(installedCertificates.isNotEmpty() && installedCertificates == archiveCertificates) {
            "The APK was not signed with this app's current signing key."
        }
    }

    fun expired(verifiedAt: Long, now: Long): Boolean =
        verifiedAt <= 0 || verifiedAt > now || now - verifiedAt > MAX_AGE_MS
}
