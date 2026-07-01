#!/bin/bash
set -e  # Bug 4修正: エラーで即終了

# Bug 1修正: GitHub からクローンせず /repo にマウントされたローカルソースを使う
echo "Copying source from /repo..."
cp -r /repo/. /build/src/

cd /build/src

echo "Running qmake..."
qmake .

echo "Running make..."
make -j$(nproc)

echo "Copying binary to /build/..."
cp ${COPY_TARGET_BIN:-FT_SCServo_Debug_Qt} /build/

echo "Build successful."
