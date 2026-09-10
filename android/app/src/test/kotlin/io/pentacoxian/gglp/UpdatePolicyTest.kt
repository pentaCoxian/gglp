package io.pentacoxian.gglp

import org.junit.Assert.assertFalse
import org.junit.Assert.assertTrue
import org.junit.Test

class UpdatePolicyTest {
    private val checksum = "a".repeat(64)

    @Test fun higherVersionWithMatchingMetadataIsAccepted() {
        UpdatePolicy.validateRequest("io.pentacoxian.gglp", "io.pentacoxian.gglp", 11, 10, "0.9.1", 100, checksum)
        archive()
    }

    @Test fun equalAndOlderVersionsAreRejected() {
        for (version in listOf(9L, 10L)) rejects {
            UpdatePolicy.validateRequest("gglp", "gglp", version, 10, "0.9.1", 100, checksum)
        }
    }

    @Test fun wrongPackageIsRejected() {
        rejects { UpdatePolicy.validateRequest("other", "gglp", 11, 10, "0.9.1", 100, checksum) }
        rejects { archive(actualPackage = "other") }
    }

    @Test fun malformedMetadataIsRejected() {
        for (size in listOf(0L, -1L, UpdatePolicy.MAX_APK_BYTES + 1)) rejects {
            UpdatePolicy.validateRequest("gglp", "gglp", 11, 10, "0.9.1", size, checksum)
        }
        rejects { UpdatePolicy.validateRequest("gglp", "gglp", 11, 10, "", 100, checksum) }
        rejects { UpdatePolicy.validateRequest("gglp", "gglp", 11, 10, "0.9.1", 100, "bad") }
    }

    @Test fun actualApkVersionMustMatchMetadata() {
        rejects { archive(actualVersion = 12) }
        rejects { archive(actualName = "0.9.2") }
    }

    @Test fun wrongKeyEmptyKeyAndHistoricalKeysAreRejected() {
        rejects { archive(certificates = setOf("other-key")) }
        rejects { archive(certificates = emptySet()) }
        rejects { archive(certificates = setOf("current-key", "old-key")) }
    }

    @Test fun unsupportedAndroidVersionIsRejected() {
        rejects { archive(minSdk = 37) }
    }

    @Test fun cacheExpiresAfterSevenDaysAndRejectsFutureDates() {
        val now = UpdatePolicy.MAX_AGE_MS + 1000
        assertFalse(UpdatePolicy.expired(1000, now))
        assertTrue(UpdatePolicy.expired(999, now))
        assertTrue(UpdatePolicy.expired(now + 1, now))
        assertTrue(UpdatePolicy.expired(0, now))
    }

    private fun archive(actualPackage: String = "gglp", actualVersion: Long = 11,
        actualName: String = "0.9.1", minSdk: Int = 21,
        certificates: Set<String> = setOf("current-key")) = UpdatePolicy.validateArchive(
        "gglp", 11, "0.9.1", actualPackage, actualVersion, actualName, minSdk, 36,
        setOf("current-key"), certificates)

    private fun rejects(block: () -> Unit) {
        try { block(); throw AssertionError("Expected validation to reject the update.") }
        catch (_: IllegalArgumentException) { }
    }
}
