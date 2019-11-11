# Builds a Libpng framework for the iPhone and the iPhone Simulator.
# Creates a set of universal libraries that can be used on an iPhone and in the
# iPhone simulator. Then creates a pseudo-framework to make using libpng in Xcode
# less painful.
#
# To configure the script, define:
#    IPHONE_SDKVERSION: iPhone SDK version (e.g. 8.1)
#
# Then go get the source tar.bz of the libpng you want to build, shove it in the
# same directory as this script, and run "./libpng.sh". Grab a cuppa. And voila.
#===============================================================================

: ${LIB_VERSION:=1.6.37}

# Current iPhone SDK
#: ${IPHONE_SDKVERSION:=`xcodebuild -showsdks | grep iphoneos | egrep "[[:digit:]]+\.[[:digit:]]+" -o | tail -1`}
# Specific iPhone SDK
: ${IPHONE_SDKVERSION:=10}

: ${XCODE_ROOT:=`xcode-select -print-path`}

: ${TARBALLDIR:=`pwd`}
: ${SRCDIR:=`pwd`/src}
: ${IOSBUILDDIR:=`pwd`/ios/build}
: ${OSXBUILDDIR:=`pwd`/osx/build}
: ${PREFIXDIR:=`pwd`/ios/prefix}
: ${IOSFRAMEWORKDIR:=`pwd`/ios/framework}
: ${OSXFRAMEWORKDIR:=`pwd`/osx/framework}

: ${iphonesdk_isysroot:=`xcrun --sdk iphoneos --show-sdk-path`}

LIB_TARBALL=$TARBALLDIR/libpng-$LIB_VERSION.tar.xz
LIB_SRC=$SRCDIR/libpng-${LIB_VERSION}

#===============================================================================
ARM_DEV_CMD="xcrun --sdk iphoneos"
SIM_DEV_CMD="xcrun --sdk iphonesimulator"

#===============================================================================
# Functions
#===============================================================================

abort()
{
    echo
    echo "Aborted: $@"
    exit 1
}

doneSection()
{
    echo
    echo "================================================================="
    echo "Done"
    echo
}

#===============================================================================

cleanEverythingReadyToStart()
{
    echo Cleaning everything before we start to build...

    rm -rf iphone-build iphonesim-build
    rm -rf $IOSBUILDDIR
	rm -rf $OSXBUILDDIR
    rm -rf $PREFIXDIR
    rm -rf $IOSFRAMEWORKDIR/$FRAMEWORK_NAME.framework

    doneSection
}

#===============================================================================

downloadLibpng()
{
    if [ ! -s $LIB_TARBALL ]; then
        echo "Downloading libpng ${LIB_VERSION}"
        curl -L -o $LIB_TARBALL https://newcontinuum.dl.sourceforge.net/project/libpng/libpng16/${LIB_VERSION}/libpng-${LIB_VERSION}.tar.xz
		#https://downloads.sourceforge.net/project/libpng/libpng16/1.6.37/libpng-1.6.37.tar.xz
    fi

    doneSection
}

#===============================================================================

unpackLibpng()
{
    [ -f "$LIB_TARBALL" ] || abort "Source tarball missing."

    echo Unpacking libpng into $SRCDIR...

    [ -d $SRCDIR ]    || mkdir -p $SRCDIR
    [ -d $LIB_SRC ] || ( cd $SRCDIR; tar xfj $LIB_TARBALL )
    [ -d $LIB_SRC ] && echo "    ...unpacked as $LIB_SRC"

    doneSection
}

#===============================================================================

buildLibpngForIPhoneOS()
{
    export CC=$XCODE_ROOT/Toolchains/XcodeDefault.xctoolchain/usr/bin/clang
    export CC_BASENAME=clang

    export CXX=$XCODE_ROOT/Toolchains/XcodeDefault.xctoolchain/usr/bin/clang++
    export CXX_BASENAME=clang++

    # avoid the `LDFLAGS` env to include the homebrew Cellar
    export LDFLAGS=""
    
    cd $LIB_SRC

    #echo Building Libpng for iPhoneSimulator
    #export CFLAGS="-O3 -arch i386 -arch x86_64 -isysroot $XCODE_ROOT/Platforms/iPhoneSimulator.platform/Developer/SDKs/iPhoneSimulator${IPHONE_SDKVERSION}.sdk -mios-simulator-version-min=${IPHONE_SDKVERSION} -Wno-error-implicit-function-declaration"
    #make distclean
    #./configure --prefix=$PREFIXDIR/iphonesim-build --disable-dependency-tracking --enable-static=yes --enable-shared=no
    #make
    #make install
    #doneSection

    echo Building Libpng for iPhone
    export CFLAGS="-O3 -arch armv7 -arch armv7s -arch arm64 -isysroot ${iphonesdk_isysroot}  -mios-version-min=${IPHONE_SDKVERSION}"
    make distclean
    ./configure --host=arm-apple-darwin --prefix=$PREFIXDIR/iphone-build --disable-dependency-tracking --enable-static=yes --enable-shared=no
    make
    make install
    doneSection
	
    export CC=clang
    export CC_BASENAME=clang

    export CXX=clang++
    export CXX_BASENAME=clang++
	
    echo Building Libpng for Mac OS X
    export CFLAGS="-O3 -arch x86_64 -arch i386"
    make distclean
    ./configure --prefix=$PREFIXDIR/macosx-build --disable-dependency-tracking --enable-static=yes --enable-shared=no
    make
    make install
    doneSection
}

#===============================================================================

scrunchAllLibsTogetherInOneLibPerPlatform()
{
    cd $PREFIXDIR

    # iOS Device
    mkdir -p $IOSBUILDDIR/armv7
    mkdir -p $IOSBUILDDIR/armv7s
    mkdir -p $IOSBUILDDIR/arm64

    # iOS Simulator
    #mkdir -p $IOSBUILDDIR/i386
    #mkdir -p $IOSBUILDDIR/x86_64
	
	# Mac OS X
    mkdir -p $OSXBUILDDIR/i386
    mkdir -p $OSXBUILDDIR/x86_64

    ALL_LIBS=""

    echo Splitting all existing fat binaries...

    $ARM_DEV_CMD lipo "iphone-build/lib/libpng.a" -thin armv7 -o $IOSBUILDDIR/armv7/libpng.a
    $ARM_DEV_CMD lipo "iphone-build/lib/libpng.a" -thin armv7s -o $IOSBUILDDIR/armv7s/libpng.a
    $ARM_DEV_CMD lipo "iphone-build/lib/libpng.a" -thin arm64 -o $IOSBUILDDIR/arm64/libpng.a

    #$SIM_DEV_CMD lipo "iphonesim-build/lib/libpng.a" -thin i386 -o $IOSBUILDDIR/i386/libpng.a
    #$SIM_DEV_CMD lipo "iphonesim-build/lib/libpng.a" -thin x86_64 -o $IOSBUILDDIR/x86_64/libpng.a
	
    lipo "macosx-build/lib/libpng.a" -thin i386 -o $OSXBUILDDIR/i386/libpng.a
    lipo "macosx-build/lib/libpng.a" -thin x86_64 -o $OSXBUILDDIR/x86_64/libpng.a

    echo Build an universal library
}

#===============================================================================
# Execution starts here
#===============================================================================

mkdir -p $IOSBUILDDIR
mkdir -p $OSXBUILDDIR

# cleanEverythingReadyToStart #may want to comment if repeatedly running during dev

echo "LIB_VERSION:       $LIB_VERSION"
echo "LIB_SRC:           $LIB_SRC"
echo "IOSBUILDDIR:       $IOSBUILDDIR"
echo "OSXBUILDDIR:       $OSXBUILDDIR"
echo "PREFIXDIR:         $PREFIXDIR"
echo "IOSFRAMEWORKDIR:   $IOSFRAMEWORKDIR"
echo "IPHONE_SDKVERSION: $IPHONE_SDKVERSION"
echo "XCODE_ROOT:        $XCODE_ROOT"
echo

downloadLibpng
unpackLibpng
buildLibpngForIPhoneOS
scrunchAllLibsTogetherInOneLibPerPlatform

echo "Completed successfully"

#===============================================================================