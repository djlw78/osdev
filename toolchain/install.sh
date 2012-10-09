#!/bin/bash
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

. $DIR/config.sh
. $DIR/util.sh

pushd build
    if [ ! -d binutils ]; then
        mkdir binutils
    fi
    pushd binutils
        $DIR/tarballs/binutils-2.22/configure --target=$TARGET --prefix=$PREFIX || bail
        make || bail
        make install || bail
    popd
    export PATH=$PATH:$PREFIX/bin
    if [ ! -d gcc ]; then
        mkdir gcc
    fi
    pushd gcc
        $DIR/tarballs/gcc-4.6.0/configure --target=$TARGET --prefix=$PREFIX --disable-nls --enable-languages=c || bail
        make all-gcc || bail
        make install-gcc || bail
        make all-target-libgcc || bail
        make install-target-libgcc || bail
    popd
    if [ ! -d newlib ]; then
        mkdir newlib
    fi
    pushd $DIR/tarballs/newlib-1.19.0/newlib/libc/sys
        autoconf || bail
        pushd toaru
            autoreconf || bail
            yasm -f elf -o crt0.o crt0.s || bail
            cp crt0.o ../
            cp crt0.o /tmp/__toaru_crt0.o
        popd
    popd
    pushd newlib
        mkdir -p $TARGET/newlib/libc/sys
        cp /tmp/__toaru_crt0.o $TARGET/newlib/libc/sys/crt0.o
        rm /tmp/__toaru_crt0.o
        $DIR/tarballs/newlib-1.19.0/configure --target=$TARGET --prefix=$PREFIX || bail
        make || bail
        make install || bail
        cp $DIR/patches/newlib/syscall.h $PREFIX/$TARGET/include/
    popd
    if [ ! -d freetype ]; then
        mkdir freetype
    fi
    pushd freetype
        $DIR/tarballs/freetype-2.4.9/configure --host=$TARGET --prefix=$PREFIX/$TARGET || bail
        make || bail
        make install || bail
    popd
    #
    # XXX zlib can not be built in a separate directory
    #
    pushd ../tarballs/zlib*
        CC=i686-pc-toaru-gcc ./configure --static --prefix=$PREFIX/$TARGET --solo || bail
        make || bail
        make install || bail
    popd
    if [ ! -d libpng ]; then
        mkdir libpng
    fi
    pushd libpng
        $DIR/tarballs/libpng-1.5.13/configure --host=$TARGET --prefix=$PREFIX/$TARGET || bail
        make || bail
        make install || bail
    popd
popd