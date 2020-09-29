mkdir -p ${PACKAGES}
# Create the filesystem hierarchy
mkdir -p ${PACKAGES}/build
mkdir -p ${PACKAGES}/build/{bin,boot{,grub},dev,{etc/,}opt,home,lib/{firmware,modules},lib64,mnt}
mkdir -p ${PACKAGES}/build/{proc,media/{floppy,cdrom},sbin,srv,sys}
mkdir -p ${PACKAGES}/build/var/{lock,log,mail,run,spool}
mkdir -p ${PACKAGES}/build/var/{opt,cache,lib/{misc,locate},local}
install -d -m 0750 ${PACKAGES}/build/root
install -d -m 1777 ${PACKAGES}/build{/var,}/tmp
install -d ${PACKAGES}/build/etc/init.d
mkdir -p ${PACKAGES}/build/usr/{,local/}{bin,include,lib{,64},sbin,src}
mkdir -p ${PACKAGES}/build/usr/{,local/}share/{doc,info,locale,man}
mkdir -p ${PACKAGES}/build/usr/{,local/}share/{misc,terminfo,zoneinfo}
mkdir -p ${PACKAGES}/build/usr/{,local/}share/man/man{1,2,3,4,5,6,7,8}
for dir in ${PACKAGES}/build/usr{,/local}; do
    ln -s share/{man,doc,info} ${dir}
done
mkdir -p ${PACKAGES}/build/boot/grub
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
mv -v ${PACKAGES}/build/usr/bin/{cat,chgrp,chmod,chown,cp,date,dd,df,echo} ${PACKAGES}/build/bin
mv -v ${PACKAGES}/build/usr/bin/{false,ln,ls,mkdir,mknod,mv,pwd,rm} ${PACKAGES}/build/bin
mv -v ${PACKAGES}/build/usr/bin/{rmdir,stty,sync,true,uname} ${PACKAGES}/build/bin
mv -v ${PACKAGES}/build/usr/bin/{head,nice,sleep,touch} ${PACKAGES}/build/bin
mv -v ${PACKAGES}/build/usr/bin/chroot ${PACKAGES}/build/usr/sbin
mkdir -pv ${PACKAGES}/build/usr/share/man/man8
mv -v ${PACKAGES}/build/usr/share/man/man1/chroot.1 ${PACKAGES}/build/usr/share/man/man8/chroot.8
sed -i 's/"1"/"8"/' ${PACKAGES}/build/usr/share/man/man8/chroot.8
cd ../

# TODO: Download util-linux source tarball, uncompress tarball, change directory into it
echo "Building util-linux-${UTIL_LINUX_VERSION}"
wget https://mirrors.edge.kernel.org/pub/linux/utils/util-linux/v${UTIL_LINUX_VERSION}/util-linux-${UTIL_LINUX_VERSION}.tar.xz
tar -xJf util-linux-${UTIL_LINUX_VERSION}.tar.xz
cd util-linux-${UTIL_LINUX_VERSION}
./autogen.sh && ./configure && make && make DESTDIR=${PACKAGES}/build/ install
cd ../
