# game/app specific values
export APP_VERSION="8.10"
export ICONSDIR="../MSPBuildSystem/yquake2"
export ICONSFILENAME="quake2"
export PORT_NAME="Yamagi Quake II"
export PRODUCT_NAME="yquake2"
export EXECUTABLE_NAME="quake2"
export PKGINFO="APPLGYQ2"
export COPYRIGHT_TEXT="Quake II Copyright © 1997-2012 id Software, Inc. All rights reserved."
export GIT_TAG="QUAKE2_8_10"
export GIT_DEFAULT_BRANCH="master"

#constants
source ../common/constants.sh

cd ../../yquake2

# reset to the main branch
echo git checkout ${GIT_DEFAULT_BRANCH}
git checkout ${GIT_DEFAULT_BRANCH}

# fetch the latest 
echo git pull
git pull

# check out the latest release tag
echo git checkout tags/${GIT_TAG}
git checkout tags/${GIT_TAG}

rm -rf ${BUILT_PRODUCTS_DIR}

ARM64_CFLAGS="-I/opt/homebrew/include -I/opt/homebrew/opt/openal-soft/include -mmacosx-version-min=10.9"
ARM64_LDFLAGS="-L/opt/homebrew/lib -L/opt/homebrew/opt/openal-soft/lib -mmacosx-version-min=10.9"
x86_64_CFLAGS="-mmacosx-version-min=10.9"
x86_64_LDFLAGS="-mmacosx-version-min=10.9"

(YQ2_ARCH=x86_64 make clean) || exit 1;
(YQ2_ARCH=x86_64 CFLAGS=$x86_64_CFLAGS  LDFLAGS=$x86_64_LDFLAGS make -j$NCPU) || exit 1;
mkdir -p ${X86_64_BUILD_FOLDER}/${EXECUTABLE_FOLDER_PATH}
mv release/* ${X86_64_BUILD_FOLDER}/${EXECUTABLE_FOLDER_PATH}
rm -rd release

(YQ2_ARCH=arm64 make clean) || exit 1;
(YQ2_ARCH=arm64 CFLAGS=$ARM64_CFLAGS  LDFLAGS=$ARM64_LDFLAGS make -j$NCPU) || exit 1;
mkdir -p ${ARM64_BUILD_FOLDER}/${EXECUTABLE_FOLDER_PATH}
mv release/* ${ARM64_BUILD_FOLDER}/${EXECUTABLE_FOLDER_PATH}
rm -rd release

# create the app bundle
"../MSPBuildSystem/common/build_app_bundle.sh"

#create any app-specific directories
if [ ! -d "${BUILT_PRODUCTS_DIR}/${EXECUTABLE_FOLDER_PATH}/baseq2" ]; then
	mkdir -p "${BUILT_PRODUCTS_DIR}/${EXECUTABLE_FOLDER_PATH}/baseq2" || exit 1;
fi

#dylibbundler the quake2 libs
dylibbundler -od -b -x ./${X86_64_BUILD_FOLDER}/${EXECUTABLE_FOLDER_PATH}/ref_gl1.dylib -d ./${X86_64_BUILD_FOLDER}/${EXECUTABLE_FOLDER_PATH}/${X86_64_LIBS_FOLDER}/ -p @executable_path/${X86_64_LIBS_FOLDER}/
dylibbundler -od -b -x ./${X86_64_BUILD_FOLDER}/${EXECUTABLE_FOLDER_PATH}/ref_gl3.dylib -d ./${X86_64_BUILD_FOLDER}/${EXECUTABLE_FOLDER_PATH}/${X86_64_LIBS_FOLDER}/ -p @executable_path/${X86_64_LIBS_FOLDER}/
dylibbundler -od -b -x ./${X86_64_BUILD_FOLDER}/${EXECUTABLE_FOLDER_PATH}/ref_soft.dylib -d ./${X86_64_BUILD_FOLDER}/${EXECUTABLE_FOLDER_PATH}/${X86_64_LIBS_FOLDER}/ -p @executable_path/${X86_64_LIBS_FOLDER}/
dylibbundler -od -b -x ./${X86_64_BUILD_FOLDER}/${EXECUTABLE_FOLDER_PATH}/baseq2/game.dylib -d ./${X86_64_BUILD_FOLDER}/${EXECUTABLE_FOLDER_PATH}/${X86_64_LIBS_FOLDER}/ -p @executable_path/${X86_64_LIBS_FOLDER}/
dylibbundler -od -b -x ./${ARM64_BUILD_FOLDER}/${EXECUTABLE_FOLDER_PATH}/ref_gl1.dylib -d ./${ARM64_BUILD_FOLDER}/${EXECUTABLE_FOLDER_PATH}/${ARM64_LIBS_FOLDER}/ -p @executable_path/${ARM64_LIBS_FOLDER}/
dylibbundler -od -b -x ./${ARM64_BUILD_FOLDER}/${EXECUTABLE_FOLDER_PATH}/ref_gl3.dylib -d ./${ARM64_BUILD_FOLDER}/${EXECUTABLE_FOLDER_PATH}/${ARM64_LIBS_FOLDER}/ -p @executable_path/${ARM64_LIBS_FOLDER}/
dylibbundler -od -b -x ./${ARM64_BUILD_FOLDER}/${EXECUTABLE_FOLDER_PATH}/ref_soft.dylib -d ./${ARM64_BUILD_FOLDER}/${EXECUTABLE_FOLDER_PATH}/${ARM64_LIBS_FOLDER}/ -p @executable_path/${ARM64_LIBS_FOLDER}/
dylibbundler -od -b -x ./${ARM64_BUILD_FOLDER}/${EXECUTABLE_FOLDER_PATH}/baseq2/game.dylib -d ./${ARM64_BUILD_FOLDER}/${EXECUTABLE_FOLDER_PATH}/${ARM64_LIBS_FOLDER}/ -p @executable_path/${ARM64_LIBS_FOLDER}/

#lipo any app-specific things
lipo ${X86_64_BUILD_FOLDER}/${EXECUTABLE_FOLDER_PATH}/ref_gl1.dylib ${ARM64_BUILD_FOLDER}/${EXECUTABLE_FOLDER_PATH}/ref_gl1.dylib -output "${BUILT_PRODUCTS_DIR}/${EXECUTABLE_FOLDER_PATH}/ref_gl1.dylib" -create
lipo ${X86_64_BUILD_FOLDER}/${EXECUTABLE_FOLDER_PATH}/ref_gl3.dylib ${ARM64_BUILD_FOLDER}/${EXECUTABLE_FOLDER_PATH}/ref_gl3.dylib -output "${BUILT_PRODUCTS_DIR}/${EXECUTABLE_FOLDER_PATH}/ref_gl3.dylib" -create
lipo ${X86_64_BUILD_FOLDER}/${EXECUTABLE_FOLDER_PATH}/ref_soft.dylib ${ARM64_BUILD_FOLDER}/${EXECUTABLE_FOLDER_PATH}/ref_soft.dylib -output "${BUILT_PRODUCTS_DIR}/${EXECUTABLE_FOLDER_PATH}/ref_soft.dylib" -create
lipo ${X86_64_BUILD_FOLDER}/${EXECUTABLE_FOLDER_PATH}/baseq2/game.dylib ${ARM64_BUILD_FOLDER}/${EXECUTABLE_FOLDER_PATH}/baseq2/game.dylib -output "${BUILT_PRODUCTS_DIR}/${EXECUTABLE_FOLDER_PATH}/baseq2/game.dylib" -create

"../MSPBuildSystem/common/sign_and_notarize.sh" "$1"

#move app bundle to a subfolder
mkdir -p ${BUILT_PRODUCTS_DIR}/source_folder
mv ${BUILT_PRODUCTS_DIR}/${WRAPPER_NAME} ${BUILT_PRODUCTS_DIR}/source_folder

#create DMG from that subfolder
create-dmg \
  --volname "${PORT_NAME}" \
  --volicon "../MSPBuildSystem/common/msp_dmg.icns" \
  --background "../MSPBuildSystem/common/msp_dmg_background.png" \
  --window-pos 200 120 \
  --window-size 750 400 \
  --icon-size 100 \
  --icon "${WRAPPER_NAME}" 175 190 \
  --hide-extension "${WRAPPER_NAME}" \
  --app-drop-link 575 185 \
  --no-internet-enable \
  "${BUILT_PRODUCTS_DIR}/${PRODUCT_NAME}.dmg" \
  "${BUILT_PRODUCTS_DIR}/source_folder"

#move app bundle back to parent folder
mv ${BUILT_PRODUCTS_DIR}/source_folder/${WRAPPER_NAME} ${BUILT_PRODUCTS_DIR}
rm -rd ${BUILT_PRODUCTS_DIR}/source_folder

if [ -d "../MSPBuildSystem/yquake2/release-${APP_VERSION}" ]; then
	rm -rf "../MSPBuildSystem/yquake2/release-${APP_VERSION}" || exit 1;
fi
mkdir -p "../MSPBuildSystem/yquake2/release-${APP_VERSION}";

mv ${BUILT_PRODUCTS_DIR}/* "../MSPBuildSystem/yquake2/release-${APP_VERSION}"

rm -rf ${X86_64_BUILD_FOLDER}
rm -rf ${ARM64_BUILD_FOLDER}
rm -rf ${BUILT_PRODUCTS_DIR}
