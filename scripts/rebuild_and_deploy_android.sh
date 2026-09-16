#!/bin/bash
set -e
cd /Users/shyudi/Fitness_App/app
echo "Building Android APK..."
fvm flutter build apk --release
echo "Uploading APK to server download dir..."
sshpass -p 1707 scp -o ConnectTimeout=30 -o StrictHostKeyChecking=no -o ServerAliveInterval=10 -o ServerAliveCountMax=12 \
  build/app/outputs/flutter-apk/app-release.apk "yudi@192.168.1.44:C:/fitcoach/fitcoach-server/download.apk"
echo "Copying APK to install temp path on Windows..."
sshpass -p 1707 ssh -o ConnectTimeout=10 -o StrictHostKeyChecking=no yudi@192.168.1.44 \
  'cmd /c "copy /Y C:\fitcoach\fitcoach-server\download.apk C:\adb_latest.apk"' || true
echo "Installing APK on Android device..."
sshpass -p 1707 ssh -o ConnectTimeout=30 -o StrictHostKeyChecking=no yudi@192.168.1.44 \
  'cmd /c "C:\platform-tools\adb.exe -s VOL7L7Z98PFM59YH push C:\adb_latest.apk /data/local/tmp/app.apk && C:\platform-tools\adb.exe -s VOL7L7Z98PFM59YH shell pm install -r /data/local/tmp/app.apk"'
echo "Launching app on Android device..."
sshpass -p 1707 ssh -o ConnectTimeout=15 -o StrictHostKeyChecking=no yudi@192.168.1.44 \
  'cmd /c "C:\platform-tools\adb.exe -s VOL7L7Z98PFM59YH shell monkey -p in.fyzziq.app -c android.intent.category.LAUNCHER 1"'
echo "Android Done!"
