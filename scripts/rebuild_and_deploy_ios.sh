#!/bin/bash
set -e
cd /Users/shyudi/Fitness_App/app
export DEVELOPER_DIR="/Users/shyudi/Downloads/Xcode-beta 2.app/Contents/Developer"
echo "Building iOS..."
fvm flutter build ios --release --no-codesign
echo "Archiving iOS..."
xcodebuild -workspace ios/Runner.xcworkspace -scheme Runner -configuration Release -destination "id=00008110-000241C63C82401E" -archivePath build/Runner.xcarchive archive
cat > ExportOptions.plist << 'INNER_EOF'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
	<key>method</key>
	<string>development</string>
	<key>compileBitcode</key>
	<false/>
</dict>
</plist>
INNER_EOF
echo "Exporting IPA..."
xcodebuild -exportArchive -archivePath build/Runner.xcarchive -exportPath build/ipa_export3 -exportOptionsPlist ExportOptions.plist
echo "Installing on iOS device..."
xcrun devicectl device install app --device 00008110-000241C63C82401E build/ipa_export3/fyzziq_app.ipa 2>/dev/null || \
  xcrun devicectl device install app --device 00008110-000241C63C82401E build/ipa_export3/Runner.ipa 2>/dev/null || \
  xcrun devicectl device install app --device 00008110-000241C63C82401E "$(ls build/ipa_export3/*.ipa | head -1)"
echo "Launching app on iOS device..."
xcrun devicectl device process launch --device 00008110-000241C63C82401E in.fyzziq.app
echo "Uploading IPA to server..."
sshpass -p 1707 scp -o ConnectTimeout=20 -o StrictHostKeyChecking=no "$(ls build/ipa_export3/*.ipa | head -1)" "yudi@192.168.1.44:C:/fitcoach/fitcoach-server/download.ipa"
echo "iOS Done!"
