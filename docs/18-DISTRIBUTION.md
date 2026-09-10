# 18 — Distribution

## Development

- Xcode project/workspace.
- Debug build.
- Release build.
- Automated tests.

## Release

Prepare scripts/documentation for:
- archive;
- signing;
- notarization;
- DMG creation.

Never commit certificates, private keys, passwords, notarization secrets, or provisioning secrets.

### Packaging script

MacSweep provides an automated release packaging script at `scripts/package-release.sh`.

#### Local / development packaging (ad-hoc):
```bash
./scripts/package-release.sh
```
This builds a universal Release binary, signs ad-hoc with Hardened Runtime enabled, creates a compressed disk image (`build/MacSweep.dmg`), and verifies its checksum.

#### Developer ID distribution & notarization:
```bash
export DEVELOPER_ID_APPLICATION="Developer ID Application: Your Name (TEAMID)"
export APPLE_ID="developer@example.com"
export TEAM_ID="ABCDE12345"
export APP_SPECIFIC_PASSWORD="xxxx-xxxx-xxxx-xxxx"

./scripts/package-release.sh
```
The script will:
1. Build universal release binaries (`x86_64` + `arm64`).
2. Sign the `.app` bundle with Developer ID certificate and Hardened Runtime (`--options runtime`).
3. Submit archive to Apple's notary service using `xcrun notarytool` and wait for approval.
4. Staple the notarization ticket to the app bundle (`xcrun stapler staple`).
5. Create a compressed DMG with an `/Applications` symlink.
6. Sign and staple the final DMG.
7. Verify disk image checksum with `hdiutil verify`.

All credentials remain in environment variables or keychain items; secrets are never written to source control or disk.

## First release

Distribution can initially be local/developer-only. Do not claim App Store compatibility until sandbox/entitlement requirements have been evaluated.
