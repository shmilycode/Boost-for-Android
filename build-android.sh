#!/bin/sh
# Copyright (C) 2010 Mystic Tree Games
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#      http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#
# Author: Moritz "Moss" Wundke (b.thax.dcg@gmail.com)
#
# <License>
#
# Build boost for android completly. It will download boost 1.45.0
# prepare the build system and finally build it for android

SCRIPTDIR="$(cd "$(dirname "$0")"; pwd)" # " # This extra quote fixes syntax highlighting in mcedit

# Add common build methods
. "$SCRIPTDIR"/build-common.sh

# -----------------------
# Command line arguments
# -----------------------

BOOST_VER1=1
BOOST_VER2=70
BOOST_VER3=0
register_option "--boost=<version>" boost_version "Boost version to be used, one of {1.70.0, 1.69.0, 1.68.0, 1.67.0, 1.66.0, 1.65.1, 1.55.0, 1.54.0, 1.53.0, 1.49.0, 1.48.0, 1.45.0}, default is 1.70.0."
boost_version()
{
  if [ "$1" = "1.70.0" ]; then
    BOOST_VER1=1
    BOOST_VER2=70
    BOOST_VER3=0
  elif [ "$1" = "1.69.0" ]; then
    BOOST_VER1=1
    BOOST_VER2=69
    BOOST_VER3=0    
  elif [ "$1" = "1.68.0" ]; then
    BOOST_VER1=1
    BOOST_VER2=68
    BOOST_VER3=0    
  elif [ "$1" = "1.67.0" ]; then
    BOOST_VER1=1
    BOOST_VER2=67
    BOOST_VER3=0    
  elif [ "$1" = "1.66.0" ]; then
    BOOST_VER1=1
    BOOST_VER2=66
    BOOST_VER3=0
  elif [ "$1" = "1.65.1" ]; then
    BOOST_VER1=1
    BOOST_VER2=65
    BOOST_VER3=1
  elif [ "$1" = "1.55.0" ]; then
    BOOST_VER1=1
    BOOST_VER2=55
    BOOST_VER3=0
  elif [ "$1" = "1.54.0" ]; then
    BOOST_VER1=1
    BOOST_VER2=54
    BOOST_VER3=0
  elif [ "$1" = "1.53.0" ]; then
    BOOST_VER1=1
    BOOST_VER2=53
    BOOST_VER3=0
  elif [ "$1" = "1.49.0" ]; then
    BOOST_VER1=1
    BOOST_VER2=49
    BOOST_VER3=0
  elif [ "$1" = "1.48.0" ]; then
    BOOST_VER1=1
    BOOST_VER2=48
    BOOST_VER3=0
  elif [ "$1" = "1.45.0" ]; then
    BOOST_VER1=1
    BOOST_VER2=45
    BOOST_VER3=0
  else
    echo "Unsupported boost version '$1'."
    exit 1
  fi
}

register_option "--toolchain=<toolchain>" select_toolchain "Select a toolchain. To see available execute ls -l ANDROID_NDK/toolchains."
select_toolchain () {
    TOOLCHAIN=$1
}

BOOST_DIR="$PROGDIR/boost_${BOOST_VER1}_${BOOST_VER2}_${BOOST_VER3}"
register_option "--boost_dir=<dir>" set_boostdir "Set root path of boost."
set_boostdir () {
    BOOST_DIR=$1
}

CLEAN=no
register_option "--clean"    do_clean     "Delete all previously downloaded and built files, then exit."
do_clean () {	CLEAN=yes; }

DOWNLOAD=no
register_option "--download" do_download  "Only download required files and clean up previus build. No build will be performed."

do_download ()
{
	DOWNLOAD=yes
	# Clean previus stuff too!
	CLEAN=yes
}

#LIBRARIES=--with-libraries=date_time,filesystem,program_options,regex,signals,system,thread,iostreams,locale
LIBRARIES=
register_option "--with-libraries=<list>" do_with_libraries "Comma separated list of libraries to build."
do_with_libraries () { 
  for lib in $(echo $1 | tr ',' '\n') ; do LIBRARIES="--with-$lib ${LIBRARIES}"; done 
}

register_option "--without-libraries=<list>" do_without_libraries "Comma separated list of libraries to exclude from the build."
do_without_libraries () {	LIBRARIES="--without-libraries=$1"; }
do_without_libraries () { 
  for lib in $(echo $1 | tr ',' '\n') ; do LIBRARIES="--without-$lib ${LIBRARIES}"; done 
}

register_option "--prefix=<path>" do_prefix "Prefix to be used when installing libraries and includes."
do_prefix () {
    if [ -d $1 ]; then
        PREFIX=$1;
    fi
}

ARCHLIST=
register_option "--arch=<list>" do_arch "Comma separated list of architectures to build: arm64-v8a,armeabi,armeabi-v7a,mips,mips64,x86,x86_64"
do_arch () {
  for ARCH in $(echo $1 | tr ',' '\n') ; do ARCHLIST="$ARCH ${ARCHLIST}"; done
}

ANDROID_TARGET_32=21
ANDROID_TARGET_64=21
register_option "--target-version=<version>" select_target_version \
                "Select Android's target version" "$ANDROID_TARGET_32"
select_target_version () {

    if [ "$1" -lt 16 ]; then
        ANDROID_TARGET_32="16"
        ANDROID_TARGET_64="21"
    elif [ "$1" = 20 ]; then
        ANDROID_TARGET_32="19"
        ANDROID_TARGET_64="21"
    elif [ "$1" -lt 21 ]; then
        ANDROID_TARGET_32="$1"
        ANDROID_TARGET_64="21"
    elif [ "$1" = 25 ]; then
        ANDROID_TARGET_32="24"
        ANDROID_TARGET_64="24"
    else
        ANDROID_TARGET_32="$1"
        ANDROID_TARGET_64="$1"
    fi
}

WITH_ICONV=
register_option "--with-iconv" do_with_iconv "Build iconv and icu libaries, for boost-locale"
do_with_iconv () {
  WITH_ICONV=1
}

PROGRAM_PARAMETERS="<ndk-root>"
PROGRAM_DESCRIPTION=\
"       Boost For Android\n"\
"Copyright (C) 2010 Mystic Tree Games\n"\

extract_parameters $@

echo "Building boost version: $BOOST_VER1.$BOOST_VER2.$BOOST_VER3"

# -----------------------
# Build constants
# -----------------------

BOOST_DOWNLOAD_LINK="http://downloads.sourceforge.net/project/boost/boost/$BOOST_VER1.$BOOST_VER2.$BOOST_VER3/boost_${BOOST_VER1}_${BOOST_VER2}_${BOOST_VER3}.tar.bz2?r=http%3A%2F%2Fsourceforge.net%2Fprojects%2Fboost%2Ffiles%2Fboost%2F${BOOST_VER1}.${BOOST_VER2}.${BOOST_VER3}%2F&ts=1291326673&use_mirror=garr"
BOOST_TAR="boost_${BOOST_VER1}_${BOOST_VER2}_${BOOST_VER3}.tar.bz2"
BUILD_DIR="./build/"

# -----------------------

if [ $CLEAN = yes ] ; then
	echo "Cleaning: $BUILD_DIR"
	rm -f -r $PROGDIR/$BUILD_DIR
	
	echo "Cleaning: $BOOST_DIR"
	rm -f -r $BOOST_DIR
	
	echo "Cleaning: $BOOST_TAR"
	rm -f $PROGDIR/$BOOST_TAR

	echo "Cleaning: logs"
	rm -f -r logs
	rm -f build.log

  [ "$DOWNLOAD" = "yes" ] || exit 0
fi

AndroidNDKRoot=$PARAMETERS
if [ -z "$AndroidNDKRoot" ] ; then
  if [ -n "${ANDROID_BUILD_TOP}" ]; then # building from Android sources
    AndroidNDKRoot="${ANDROID_BUILD_TOP}/prebuilts/ndk/current"
    export AndroidSourcesDetected=1
  elif [ -z "`which ndk-build`" ]; then
    dump "ERROR: You need to provide a <ndk-root>!"
    exit 1
  else
    AndroidNDKRoot=`which ndk-build`
    AndroidNDKRoot=`dirname $AndroidNDKRoot`
  fi
  echo "Using AndroidNDKRoot = $AndroidNDKRoot"
else
  # User passed the NDK root as a parameter. Make sure the directory
  # exists and make it an absolute path. ".cmd" is for Windows support.
  if [ ! -f "$AndroidNDKRoot/ndk-build" ] && [ ! -f "$AndroidNDKRoot/ndk-build.cmd" ]; then
    dump "ERROR: $AndroidNDKRoot is not a valid NDK root"
    exit 1
  fi
  AndroidNDKRoot=$(cd $AndroidNDKRoot; pwd -P)
fi
export AndroidNDKRoot

# Check platform patch
case "$HOST_OS" in
    linux)
        PlatformOS=linux
        ;;
    darwin|freebsd)
        PlatformOS=darwin
        ;;
    windows|cygwin)
        PlatformOS=windows
        ;;
    *)  # let's play safe here
        PlatformOS=linux
esac

NDK_RELEASE_FILE=$AndroidNDKRoot"/RELEASE.TXT"
if [ -f "${NDK_RELEASE_FILE}" ]; then
    NDK_RN=`cat $NDK_RELEASE_FILE | sed 's/^r\(.*\)$/\1/g'`
elif [ -n "${AndroidSourcesDetected}" ]; then
    if [ -f "${ANDROID_BUILD_TOP}/ndk/docs/CHANGES.html" ]; then
        NDK_RELEASE_FILE="${ANDROID_BUILD_TOP}/ndk/docs/CHANGES.html"
        NDK_RN=`grep "android-ndk-" "${NDK_RELEASE_FILE}" | head -1 | sed 's/^.*r\(.*\)$/\1/'`
    elif [ -f "${ANDROID_BUILD_TOP}/ndk/docs/text/CHANGES.text" ]; then
        NDK_RELEASE_FILE="${ANDROID_BUILD_TOP}/ndk/docs/text/CHANGES.text"
        NDK_RN=`grep "android-ndk-" "${NDK_RELEASE_FILE}" | head -1 | sed 's/^.*r\(.*\)$/\1/'`
    else
        dump "ERROR: can not find ndk version"
        exit 1
    fi
else
    NDK_RELEASE_FILE=$AndroidNDKRoot"/source.properties"
    if [ -f "${NDK_RELEASE_FILE}" ]; then
        NDK_RN=`cat $NDK_RELEASE_FILE | grep 'Pkg.Revision' | sed -E 's/^.*[=] *([0-9]+[.][0-9]+)[.].*/\1/g'`
    else
        dump "ERROR: can not find ndk version"
        exit 1
    fi
fi

echo "Detected Android NDK version $NDK_RN"

CONFIG_VARIANT=boost

case "$NDK_RN" in
	4*)
		TOOLCHAIN=${TOOLCHAIN:-arm-eabi-4.4.0}
		CXXPATH=$AndroidNDKRoot/build/prebuilt/$PlatformOS-x86/${TOOLCHAIN}/bin/arm-eabi-g++
		TOOLSET=gcc-androidR4
		;;
	5*)
		TOOLCHAIN=${TOOLCHAIN:-arm-linux-androideabi-4.4.3}
		CXXPATH=$AndroidNDKRoot/toolchains/${TOOLCHAIN}/prebuilt/$PlatformOS-x86/bin/arm-linux-androideabi-g++
		TOOLSET=gcc-androidR5
		;;
	7-crystax-5.beta3)
		TOOLCHAIN=${TOOLCHAIN:-arm-linux-androideabi-4.6.3}
		CXXPATH=$AndroidNDKRoot/toolchains/${TOOLCHAIN}/prebuilt/$PlatformOS-x86/bin/arm-linux-androideabi-g++
		TOOLSET=gcc-androidR7crystax5beta3
		;;
	8)
		TOOLCHAIN=${TOOLCHAIN:-arm-linux-androideabi-4.4.3}
		CXXPATH=$AndroidNDKRoot/toolchains/${TOOLCHAIN}/prebuilt/$PlatformOS-x86/bin/arm-linux-androideabi-g++
		TOOLSET=gcc-androidR8
		;;
	8b|8c|8d)
		TOOLCHAIN=${TOOLCHAIN:-arm-linux-androideabi-4.6}
		CXXPATH=$AndroidNDKRoot/toolchains/${TOOLCHAIN}/prebuilt/$PlatformOS-x86/bin/arm-linux-androideabi-g++
		TOOLSET=gcc-androidR8b
		;;
	8e|9|9b|9c|9d)
		TOOLCHAIN=${TOOLCHAIN:-arm-linux-androideabi-4.6}
		CXXPATH=$AndroidNDKRoot/toolchains/${TOOLCHAIN}/prebuilt/$PlatformOS-x86/bin/arm-linux-androideabi-g++
		TOOLSET=gcc-androidR8e
		;;
	"8e (64-bit)")
		TOOLCHAIN=${TOOLCHAIN:-arm-linux-androideabi-4.6}
		CXXPATH=$AndroidNDKRoot/toolchains/${TOOLCHAIN}/prebuilt/${PlatformOS}-x86_64/bin/arm-linux-androideabi-g++
		TOOLSET=gcc-androidR8e
		;;
	"9 (64-bit)"|"9b (64-bit)"|"9c (64-bit)"|"9d (64-bit)")
		TOOLCHAIN=${TOOLCHAIN:-arm-linux-androideabi-4.6}
		CXXPATH=$AndroidNDKRoot/toolchains/${TOOLCHAIN}/prebuilt/${PlatformOS}-x86_64/bin/arm-linux-androideabi-g++
		TOOLSET=gcc-androidR8e
		;;
	"10 (64-bit)"|"10b (64-bit)"|"10c (64-bit)"|"10d (64-bit)")
		TOOLCHAIN=${TOOLCHAIN:-arm-linux-androideabi-4.6}
		CXXPATH=$AndroidNDKRoot/toolchains/${TOOLCHAIN}/prebuilt/${PlatformOS}-x86_64/bin/arm-linux-androideabi-g++
		TOOLSET=gcc-androidR8e
		;;
	"10 (64-bit)"|"10b (64-bit)"|"10c (64-bit)"|"10d (64-bit)")
		TOOLCHAIN=${TOOLCHAIN:-arm-linux-androideabi-4.6}
		CXXPATH=$AndroidNDKRoot/toolchains/${TOOLCHAIN}/prebuilt/${PlatformOS}-x86_64/bin/arm-linux-androideabi-g++
		TOOLSET=gcc-androidR8e
		;;
	"16.0"|"16.1"|"17.1"|"17.2"|"18.0"|"18.1")
		TOOLCHAIN=${TOOLCHAIN:-llvm}
		CXXPATH=$AndroidNDKRoot/toolchains/${TOOLCHAIN}/prebuilt/${PlatformOS}-x86_64/bin/clang++
		TOOLSET=clang
		;;
	"19.0"|"19.1"|"19.2"|"20.0")
		TOOLCHAIN=${TOOLCHAIN:-llvm}
		CXXPATH=$AndroidNDKRoot/toolchains/${TOOLCHAIN}/prebuilt/${PlatformOS}-x86_64/bin/clang++
		TOOLSET=clang
		CONFIG_VARIANT=ndk19
		;;
	*)
		echo "Undefined or not supported Android NDK version: $NDK_RN"
		exit 1
esac

if [ -n "${AndroidSourcesDetected}" -a "${TOOLSET}" '!=' "clang" ]; then # Overwrite CXXPATH if we are building from Android sources
    CXXPATH="${ANDROID_TOOLCHAIN}/arm-linux-androideabi-g++"
fi

if [ -z "${ARCHLIST}" ]; then
  ARCHLIST=armeabi-v7a
  if [ "$TOOLSET" = "clang" ]; then

    case "$NDK_RN" in
      # NDK 17+: Support for ARMv5 (armeabi), MIPS, and MIPS64 has been removed.
      "17.1"|"17.2"|"18.0"|"18.1"|"19.0"|"19.1"|"19.2"|"20.0")
        ARCHLIST="arm64-v8a armeabi-v7a x86 x86_64"
        ;;
      *)
        ARCHLIST="arm64-v8a armeabi armeabi-v7a mips mips64 x86 x86_64"
    esac    
  fi
fi

if [ "${ARCHLIST}" '!=' "armeabi" ] && [ "${TOOLSET}" '!=' "clang" ]; then
    echo "Old NDK versions only support ARM architecture"
    exit 1
fi

echo Building with TOOLSET=$TOOLSET CONFIG_VARIANT=${CONFIG_VARIANT} CXXPATH=$CXXPATH CFLAGS=$CFLAGS CXXFLAGS=$CXXFLAGS | tee $PROGDIR/build.log

# Check if the ndk is valid or not
if [ ! -f $CXXPATH ]
then
	echo "Cannot find C++ compiler at: $CXXPATH"
	exit 1
fi

# Do clean
if [ -f $BOOST_DIR/bjam ]
then
  rm $BOOST_DIR/b2*
  rm $BOOST_DIR/bjam*
  rm $BOOST_DIR/bin.v2*
fi

# ---------
# Bootstrap
# ---------
if [ ! -f $BOOST_DIR/bjam ]
then
  # Make the initial bootstrap
  echo "Performing boost bootstrap"

  cd $BOOST_DIR 
  case "$HOST_OS" in
    windows)
        cmd //c "bootstrap.bat" 2>&1 | tee -a $PROGDIR/build.log
        ;;
    *)  # Linux and others
        ./bootstrap.sh 2>&1 | tee -a $PROGDIR/build.log
    esac


  if [ $? != 0 ] ; then
  	dump "ERROR: Could not perform boostrap! See $TMPLOG for more info."
  	exit 1
  fi
  cd $PROGDIR
  
  # -------------------------------------------------------------
  # Patching will be done only if we had a successfull bootstrap!
  # -------------------------------------------------------------

  # Apply patches to boost
  BOOST_VER=${BOOST_VER1}_${BOOST_VER2}_${BOOST_VER3}
  PATCH_BOOST_DIR="$SCRIPTDIR/patches/boost-${BOOST_VER}"

  if [ "$TOOLSET" = "clang" ]; then
      cp "$SCRIPTDIR"/configs/user-config-${CONFIG_VARIANT}-${BOOST_VER}.jam $BOOST_DIR/tools/build/src/user-config.jam || exit 1
      for FILE in "$SCRIPTDIR"/configs/user-config-${CONFIG_VARIANT}-${BOOST_VER}-*.jam; do
          ARCH="`echo $FILE | sed s%$SCRIPTDIR/configs/user-config-${CONFIG_VARIANT}-${BOOST_VER}-%% | sed s/[.]jam//`"
          if [ "$ARCH" = "common" ]; then
              continue
          fi
          JAMARCH="`echo ${ARCH} | tr -d '_-'`" # Remove all dashes, bjam does not like them
          sed "s/%ARCH%/${JAMARCH}/g" "$SCRIPTDIR"/configs/user-config-${CONFIG_VARIANT}-${BOOST_VER}-common.jam >> $BOOST_DIR/tools/build/src/user-config.jam || exit 1
          cat "$SCRIPTDIR"/configs/user-config-${CONFIG_VARIANT}-${BOOST_VER}-$ARCH.jam >> $BOOST_DIR/tools/build/src/user-config.jam || exit 1
          echo ';' >> $BOOST_DIR/tools/build/src/user-config.jam || exit 1
      done
  else
      cp "$SCRIPTDIR"/configs/user-config-${CONFIG_VARIANT}-${BOOST_VER}.jam $BOOST_DIR/tools/build/v2/user-config.jam || exit 1
  fi

  for dir in $PATCH_BOOST_DIR; do
    if [ ! -d "$dir" ]; then
      echo "Could not find directory '$dir' while looking for patches"
      exit 1
    fi

    PATCHES=`(cd $dir && ls *.patch | sort) 2> /dev/null`

    if [ -z "$PATCHES" ]; then
      echo "No patches found in directory '$dir'"
      exit 1
    fi

    for PATCH in $PATCHES; do
      PATCH=`echo $PATCH | sed -e s%^\./%%g`
      SRC_DIR=$BOOST_DIR
      PATCHDIR=`dirname $PATCH`
      PATCHNAME=`basename $PATCH`
      log "Applying $PATCHNAME into $SRC_DIR/$PATCHDIR"
      cd $SRC_DIR && patch -p1 < $dir/$PATCH && cd $PROGDIR
      if [ $? != 0 ] ; then
        dump "ERROR: Patch failure !! Please check your patches directory!"
        dump "       Try to perform a clean build using --clean ."
        dump "       Problem patch: $dir/$PATCHNAME"
        exit 1
      fi
    done
  done
fi

echo "# ---------------"
echo "# Build using NDK"
echo "# ---------------"

if [ -z "$NCPU" ]; then
	NCPU=4
	if uname -s | grep -i "linux" > /dev/null ; then
		NCPU=`cat /proc/cpuinfo | grep -c -i processor`
	fi
fi

for ARCH in $ARCHLIST; do

echo "Building boost for android for $ARCH"
(

  if [ -n "$WITH_ICONV" ] || echo $LIBRARIES | grep locale; then
    if [ -e libiconv-libicu-android ]; then
      echo "ICONV and ICU already compiled"
    else
      echo "boost_locale selected - compiling ICONV and ICU"
      git clone --depth=1 https://github.com/pelya/libiconv-libicu-android.git
      cd libiconv-libicu-android
      ./build.sh || exit 1
      cd ..
    fi
  fi

  cd $BOOST_DIR

  echo "Adding pathname: `dirname $CXXPATH`"
  # `AndroidBinariesPath` could be used by user-config-*.jam
  export AndroidBinariesPath=`dirname $CXXPATH`
  export PATH=$AndroidBinariesPath:$PATH
  export AndroidNDKRoot=$AndroidNDKRoot
  export AndroidTargetVersion32=$ANDROID_TARGET_32
  export AndroidTargetVersion64=$ANDROID_TARGET_64
  export NO_BZIP2=1
  export PlatformOS=$PlatformOS

  cflags=""
  for flag in $CFLAGS; do cflags="$cflags cflags=$flag"; done
  cxxflags=""
  for flag in $CXXFLAGS; do cxxflags="$cxxflags cxxflags=$flag"; done

  LIBRARIES_BROKEN=""
  if [ "$TOOLSET" = "clang" ]; then
      JAMARCH="`echo ${ARCH} | tr -d '_-'`" # Remove all dashes, bjam does not like them
      TOOLSET_ARCH=${TOOLSET}-${JAMARCH}
      TARGET_OS=android
      if [ "$ARCH" = "armeabi" ]; then
          if [ -z "$LIBRARIES" ]; then
              echo "Disabling boost_math library on armeabi architecture, because of broken toolchain" | tee -a $PROGDIR/build.log
              LIBRARIES_BROKEN="--without-math"
          elif echo $LIBRARIES | grep math; then
            dump "ERROR: Cannot build boost_math library for armeabi architecture because of broken toolchain"
            dump "       However, it is explicitly included"
            exit 1
          fi
      fi
  else
      TOOLSET_ARCH=${TOOLSET}
      TARGET_OS=linux
  fi

  WITHOUT_LIBRARIES=--without-python
  if [ -n "$LIBRARIES" ]; then
      unset WITHOUT_LIBRARIES
  fi

  { ./bjam -q                         \
         -d+2                         \
         --ignore-site-config         \
         -j$NCPU                      \
         target-os=${TARGET_OS}       \
         toolset=${TOOLSET_ARCH}      \
         $cflags                      \
         $cxxflags                    \
         link=static                  \
         threading=multi              \
         --layout=versioned           \
         $WITHOUT_LIBRARIES           \
         -sICONV_PATH=`pwd`/../libiconv-libicu-android/$ARCH \
         -sICU_PATH=`pwd`/../libiconv-libicu-android/$ARCH \
         --prefix=${PREFIX} \
         --hash \
         $LIBRARIES                   \
         $LIBRARIES_BROKEN            \
         install 2>&1                 \
         || { dump "ERROR: Failed to build boost for android for $ARCH!" ; rm -rf ./../$BUILD_DIR/out/$ARCH ; exit 1 ; }
  } | tee -a $PROGDIR/build.log

  # PIPESTATUS variable is defined only in Bash, and we are using /bin/sh, which is not Bash on newer Debian/Ubuntu
)

dump "Done!"

done # for ARCH in $ARCHLIST
