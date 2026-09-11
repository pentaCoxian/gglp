# GGLP

A Flutter client for Misskey with multiple accounts, combined timelines, MFM,
custom emoji, reactions, channels, and media posting. GGLP is an independent
client; it is not affiliated with Misskey's server operators.

## Screenshots

| MFM formatting | Photo grids | Link previews |
| --- | --- | --- |
| [![MFM formatting](screenshots/09-mfm-ja.png)](screenshots/09-mfm-ja.png) | [![Four-photo grid](screenshots/02c-four-photos-ja.png)](screenshots/02c-four-photos-ja.png) | [![Link previews](screenshots/03-links-ja.png)](screenshots/03-links-ja.png) |
| **Quote notes** | **Custom timelines** | **Note composer** |
| [![Quote notes](screenshots/04-quotes-ja.png)](screenshots/04-quotes-ja.png) | [![Custom timeline editor](screenshots/06-custom-editor-ja.png)](screenshots/06-custom-editor-ja.png) | [![Note composer](screenshots/07-compose-ja.png)](screenshots/07-compose-ja.png) |

Screenshots use Japanese demo posts, fictional accounts and server names.

<details>
<summary>Screenshot media credits</summary>

- Server emoji come from the public [misskey.io](https://misskey.io/api/emojis), [misskey.art](https://misskey.art/api/emojis), and [misskey.systems](https://misskey.systems/api/emojis) catalogs. Their artwork belongs to its respective creators and is not covered by GGLP's MIT license.
- Kyoto photographs: Daderot, CC0 ([garden](https://commons.wikimedia.org/wiki/File:Cherry_blossoms_-_Sh%C5%8Dsei-en_-_Kyoto,_Japan_-_DSC07031.jpg), [tree](https://commons.wikimedia.org/wiki/File:Cherry_blossoms_-_Sh%C5%8Dsei-en_-_Kyoto,_Japan_-_DSC06878.jpg), [cherry tree](https://commons.wikimedia.org/wiki/File:Cherry_blossoms_-_Sh%C5%8Dsei-en_-_Kyoto,_Japan_-_DSC06868.jpg), [garden pond](https://commons.wikimedia.org/wiki/File:Tekisui-ken_and_Ingetsu-chi_Pond_-_Sh%C5%8Dsei-en_-_Kyoto,_Japan_-_DSC06894.jpg)).
- Profile photographs: [Pavel Kovalev](https://commons.wikimedia.org/wiki/File:Portrait_of_a_cat1.jpg), [HJAndrews](https://commons.wikimedia.org/wiki/File:BAPhoto-Portrait.jpg), and [Karen Arnold](https://commons.wikimedia.org/wiki/File:Dog-portrait-1367008135LpJ.jpg), CC0.
- The [Misskey Hub](https://misskey-hub.net/ja/) card uses the site's published preview title, description and thumbnail; © its respective creators, including the Misskey Project.

</details>

## Install

Download the universal APK from [GitHub Releases](https://github.com/pentaCoxian/gglp/releases).
Android 5.0 (API 21) or later is required. Android will ask you to allow your
browser to install apps from this source. The release includes SHA-256 checksums.

The OSS app uses `io.pentacoxian.gglp`, so it can coexist with development builds
using another package ID. Accounts and drafts are separate between those apps.
Sign in through your chosen Misskey server; the browser returns via `gglp://miauth`.

## Updates and privacy

On Android, GGLP checks GitHub's latest stable release at most once daily while
foregrounded. Disable **Automatic update checks** in Settings to prevent these
automatic requests; **Check for updates** remains available. Update checks send
ordinary network request metadata to GitHub, not your Misskey credentials.

Downloading and installing an update always requires your action. GGLP checks
its size, SHA-256, package/version and APK signature, then opens Android's
installer. Android may first ask you to allow GGLP to install apps. Installation
is not silent. Only APKs signed with the same release key can update an install.

Credentials and preferences are stored locally. Posts, media and account requests
go to the Misskey server you choose, which applies its own privacy policy.
Remote media and previews can contact the hosts referenced by that content.
GGLP does not include an analytics or advertising service. Review the server's
terms and use test accounts when testing posting or moderation features.

## Develop

Use Flutter **3.29.2** / Dart **3.7.2**. The Android build uses JDK **17**, SDK
**36**, NDK **27.0.12077973**, AGP **8.9.1**, and Gradle **8.11.1**.

```sh
flutter pub get --enforce-lockfile
flutter analyze
flutter test
flutter run
```

Generated Dart models/database files are committed. After changing their inputs:

```sh
dart run build_runner build --delete-conflicting-outputs
```

The existing iOS, macOS, Windows and Linux runners are retained. APK releases and
the installer integration target Android; other platforms have no automatic
installer. Configure your own Apple signing team when building for Apple devices.
The icon source and regeneration instructions are in `assets/branding`.

Contributions should stay focused and include tests for behavior changes. Run
analysis and tests before opening a pull request. Report reproducible bugs through
[GitHub Issues](https://github.com/pentaCoxian/gglp/issues), without account tokens,
private media, passwords or other sensitive data.

## Build and release APKs

Debug APKs need no signing secrets:

```sh
flutter build apk --debug
```

Release builds require an independently backed-up signing key. Create an ignored
`android/key.properties` file with local values:

```properties
storeFile=/absolute/path/to/release.jks
storePassword=<private password>
keyAlias=release
keyPassword=<private password>
```

```sh
flutter build apk --release
```

Never commit the keystore or passwords. A lost release key prevents compatible
updates to installed APKs. Debug-signed APKs cannot update release-signed APKs.

Pull requests and `main` run tests and produce debug APK artifacts for 14 days.
A release requires a stable `v<version>` tag at the **current `main` commit**, a
successful Android CI **push** run for that exact commit, and maintainer approval.
The tag must match `pubspec.yaml`; version names and Android build numbers must
increase. Tags alone do not start releases. After CI passes, run **Android
release → Run workflow**, select `main`, and enter the tag.

The workflow builds and tests an unsigned APK without signing credentials.
A fresh runner signs the approved candidate using `apksigner`, verifies the
established GGLP signing certificate, and attests the APK and update manifest.
A separate publishing job checks source, CI, signing certificate, package,
version, alignment, checksums, and provenance tied to the same workflow run.
Neither privileged runner executes Flutter, Gradle, application code or tests.

### Required GitHub protections

These repository settings are required in addition to the workflow files.
The release guard refuses to run with missing approval environments or
unprotected `main`; adding an `environment:` entry alone does not protect it.

1. Protect `main` with a ruleset that requires pull requests and the up-to-date
   `check` status from GitHub Actions, blocks force pushes and deletion, and has
   no bypass actors. A separate ruleset requires code-owner review, with an
   administrator bypass limited to pull requests so the sole maintainer can
   merge their own changes after CI passes. This exception cannot bypass CI.
   `.github/CODEOWNERS` assigns application and workflow review to
   `@pentaCoxian`. Remove the review exception when another trusted reviewer
   is available.
2. Protect `v*` tags against updates/deletion and restrict tag creation to
   release maintainers. Review the exact source diff before creating a tag.
3. Create **release-signing** and **release-publishing** environments. For both,
   require `@pentaCoxian` approval, disable administrator bypass, and allow only
   the `main` **branch** (no tag rules or wildcards). Review the commit and
   candidate digest before signing approval; review the signed assets and
   attestation before publication approval. A sole maintainer may approve their
   own run; enable prevention of self-review when a second reviewer is available.
4. Store `ANDROID_KEYSTORE_BASE64`, `ANDROID_KEYSTORE_PASSWORD`,
   `ANDROID_KEY_ALIAS`, and `ANDROID_KEY_PASSWORD` **only in release-signing**.
   Remove repository/organization copies accessible to this repository after
   provisioning the environment from the original private credentials. GitHub
   cannot return existing secret values for migration. Do not rotate the key:
   installed apps must keep accepting updates signed by the established key.
5. Keep default workflow token permissions read-only and disable workflow PR
   approvals. Enable [release immutability](https://docs.github.com/en/code-security/how-tos/secure-your-supply-chain/establish-provenance-and-integrity/prevent-release-changes)
   for future releases. Complete these settings before enabling the new workflow.

Release assets include the APK, `update.json`, `SHA256SUMS`, and `provenance.json`.
All assets are uploaded to a draft, downloaded again and checked before
publication. Published releases are never overwritten. Consumers can verify
the signed provenance with GitHub CLI (substitute the APK name and release SHA):

```sh
gh attestation verify gglp-X.Y.Z.apk --bundle provenance.json \
  --repo pentaCoxian/gglp \
  --signer-workflow pentaCoxian/gglp/.github/workflows/release.yml \
  --source-ref refs/heads/main --source-digest RELEASE_COMMIT_SHA \
  --signer-digest RELEASE_COMMIT_SHA --deny-self-hosted-runners
```

These controls establish approved source and artifact identity; passing tests
or having an attestation does not prove code is harmless. Review remains
necessary, and a compromised repository administrator or signing key is outside
this protection boundary. Keep account recovery and signing backups secure.

Forks must use their own signing key and configure their release repository;
otherwise they must disable the updater. Change the updater repository constant in
`lib/app/updates/update_manifest.dart` to your fork before building. Keep GitHub credentials out of the application.
Fork releases also need their own certificate pin in `tool/release.py` and
repository/reviewer policy in `tool/release_guard.py`.

## License

Project-owned code is [MIT licensed](LICENSE). See
[third-party notices](THIRD_PARTY_NOTICES.md) and Settings → Licenses for dependency
licenses, including the bundled Roboto font license.
