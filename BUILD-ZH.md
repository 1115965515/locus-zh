# Locus 1.0.2 Simplified Chinese (source)

UI strings are fully translated to Simplified Chinese.
Windows cannot compile an iOS IPA — you need macOS + Xcode, or GitHub Actions.

The previous binary-patched IPA caused garbled text (乱码) because Swift string
length metadata was corrupted. Do not use binary string replacement.

## Build unsigned IPA on Mac

```bash
brew install xcodegen
cd Locus-1.0.2
xcodegen generate
xcodebuild \
  -project Locus.xcodeproj \
  -scheme Locus \
  -configuration Release \
  -sdk iphoneos \
  -destination 'generic/platform=iOS' \
  -derivedDataPath build \
  CODE_SIGNING_ALLOWED=NO \
  CODE_SIGNING_REQUIRED=NO \
  CODE_SIGN_IDENTITY="" \
  DEVELOPMENT_TEAM="" \
  clean build

mkdir -p Payload
cp -R build/Build/Products/Release-iphoneos/Locus.app Payload/
rm -rf Payload/Locus.app/_CodeSignature
zip -qry ../Locus-1.0.2-zh.ipa Payload
```

Sideload with Feather / SideStore / AltStore / Sideloadly.

## Build with GitHub Actions

Push the Locus-1.0.2 folder to GitHub, then run workflow
".github/workflows/build-zh-ipa.yml" and download the IPA artifact.
