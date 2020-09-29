mkdir -p ${PACKAGES}
cd ${PACKAGES}

# TODO: Download zlib source tarball, uncompress tarball, change directory into it
echo "Building zlib-${ZLIB_VERSION}"
wget https://zlib.net/zlib-${ZLIB_VERSION}.tar.xz -q > /dev/null
tar -xJf zlib-${ZLIB_VERSION}.tar.xz
cd zlib-${ZLIB_VERSION}
sed -i 's/-O3/-Os/g' configure
./configure --prefix=/usr --shared
make && make DESTDIR=${PACKAGES}/build/ install
cd ../

# TODO: Download Pacman source tarball, uncompress tarball, change directory into it
echo "Building pacman-${PACMAN_VERSION}"
wget https://sources.archlinux.org/other/pacman/pacman-${PACMAN_VERSION}.tar.gz -q > /dev/null
tar -xf pacman-${PACMAN_VERSION}.tar.gz
cd pacman-${PACMAN_VERSION}
./configure
make && make DESTDIR=${PACKAGES}/build/ install
cd ../

# TODO: Download Coreutils source tarball, uncompress tarball, change directory into it
echo "Building GNU coreutils-${COREUTILS_VERSION}"
wget https://ftp.gnu.org/gnu/coreutils/coreutils-${COREUTILS_VERSION}.tar.xz
tar -xJf coreutils-${COREUTILS_VERSION}.tar.xz
cd coreutils-${COREUTILS_VERSION}
./configure --prefix=/usr                     \
            --host=$LFS_TGT                   \
            --build=$(build-aux/config.guess) \
            --enable-install-program=hostname
make && make DESTDIR=${PACKAGES}/build/ install
mv -v ${CARDS}/usr/bin/{cat,chgrp,chmod,chown,cp,date,dd,df,echo} ${CARDS}/bin
mv -v ${CARDS}/usr/bin/{false,ln,ls,mkdir,mknod,mv,pwd,rm} ${CARDS}/bin
mv -v ${CARDS}/usr/bin/{rmdir,stty,sync,true,uname} ${CARDS}/bin
mv -v ${CARDS}/usr/bin/{head,nice,sleep,touch} ${CARDS}/bin
mv -v ${CARDS}/usr/bin/chroot ${CARDS}/usr/sbin
mkdir -pv ${CARDS}/usr/share/man/man8
mv -v ${CARDS}/usr/share/man/man1/chroot.1 ${CARDS}/usr/share/man/man8/chroot.8
sed -i 's/"1"/"8"/' ${CARDS}/usr/share/man/man8/chroot.8
cd ../

# TODO: Download util-linux source tarball, uncompress tarball, change directory into it
echo "Building util-linux-${UTIL_LINUX_VERSION}"
wget https://mirrors.edge.kernel.org/pub/linux/utils/util-linux/v${UTIL_LINUX_VERSION}/util-linux-${UTIL_LINUX_VERSION}.tar.xz
tar -xJf util-linux-${UTIL_LINUX_VERSION}.tar.xz
cd util-linux-${UTIL_LINUX_VERSION}
./autogen.sh && ./configure && make && make DESTDIR=${PACKAGES}/build/ install
cd ../
