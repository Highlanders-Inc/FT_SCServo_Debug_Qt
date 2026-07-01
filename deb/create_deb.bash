#!/bin/bash
set -e  # Bug 4修正: エラーで即終了

SCRIPT_DIR=$(cd $(dirname $0); pwd)
REPO_ROOT=$SCRIPT_DIR/..          # ローカルのリポジトリルート
COPY_TARGET_BIN=FT_SCServo_Debug_Qt
ARCH=${1:-amd64}
BUILD_DIR=$SCRIPT_DIR/build       # Bug 2修正: 絶対パスを使う
DEB_ROOT=$SCRIPT_DIR/deb_root
VERSION=${2:-1.1.0}
DEB_NAME=ft-scservo-debug-qt_${VERSION}_${ARCH}

# 前回のビルド成果物を削除
rm -rf ${BUILD_DIR}/src ${BUILD_DIR}/${COPY_TARGET_BIN} ${DEB_ROOT}
mkdir -p ${BUILD_DIR} ${DEB_ROOT}/usr/bin ${DEB_ROOT}/DEBIAN

if [ ${ARCH} == "arm64" ]; then
    docker run --rm --privileged multiarch/qemu-user-static --reset -p yes
fi

# Docker イメージをビルド
docker build -t deb_build -f ${SCRIPT_DIR}/dockerfile.${ARCH} ${SCRIPT_DIR}

# Bug 1修正: ローカルのソースをマウントしてビルド (GitHub クローン不要)
# Bug 3修正: -t を除去 (TTY 不要)
docker run --rm \
    -v ${REPO_ROOT}:/repo:ro \
    -v ${BUILD_DIR}:/build \
    deb_build bash /build/build.bash

# Bug 7修正: バイナリが存在するか確認してから deb を作る
if [ ! -f ${BUILD_DIR}/${COPY_TARGET_BIN} ]; then
    echo "Error: binary not found after build. Check Docker build output above." >&2
    exit 1
fi

cp ${BUILD_DIR}/${COPY_TARGET_BIN} ${DEB_ROOT}/usr/bin/

# Bug 5修正: Depends に -dev パッケージではなくランタイムライブラリを指定
cat > ${DEB_ROOT}/DEBIAN/control << CONTROL
Package: ft-scservo-debug-qt
Version: $VERSION
Section: base
Priority: optional
Architecture: $ARCH
Depends: libqt5serialport5, libqt5widgets5, libqt5core5a, libqt5gui5
Maintainer: Kotakku <Kotakkucu@gmail.com>
Description: FeeTech Servo Debug Qt
 A utility for debugging Feetech SCS/STS/HLS series serial bus servo motors.
CONTROL

dpkg-deb --build -Z xz --root-owner-group ${DEB_ROOT} ${SCRIPT_DIR}/${DEB_NAME}.deb

# Bug 8修正: 変数を使ってクリーンアップ
rm -rf ${BUILD_DIR}/src ${BUILD_DIR}/${COPY_TARGET_BIN} ${DEB_ROOT}
echo "Created: ${SCRIPT_DIR}/${DEB_NAME}.deb"
