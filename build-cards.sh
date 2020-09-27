set +h
umask 022
export CARDS=~/cards
export LC_ALL=POSIX
export PATH=${CARDS}/cross-tools/bin:/bin:/usr/bin
unset CFLAGS
unset CXXFLAGS
export CARDS_HOST=$(echo ${MACHTYPE} | sed "s/-[^-]*/-cross/")
export CARDS_TARGET=x86_64-unknown-linux-gnu
export CARDS_CPU=k8
export CARDS_ARCH=$(echo ${CARDS_TARGET} | sed -e 's/-.*//' -e 's/i.86/i386/')
export CARDS_ENDIAN=little
export CC="${CARDS_TARGET}-gcc"
export CXX="${CARDS_TARGET}-g++"
export CPP="${CARDS_TARGET}-gcc -E"
export AR="${CARDS_TARGET}-ar"
export AS="${CARDS_TARGET}-as"
export LD="${CARDS_TARGET}-ld"
export RANLIB="${CARDS_TARGET}-ranlib"
export READELF="${CARDS_TARGET}-readelf"
export STRIP="${CARDS_TARGET}-strip"

# Create the filesystem hierarchy
mkdir -p ${CARDS}
mkdir -p ${CARDS}/{bin,boot{,grub},dev,{etc/,}opt,home,lib/{firmware,modules},lib64,mnt}
mkdir -p ${CARDS}/{proc,media/{floppy,cdrom},sbin,srv,sys}
mkdir -p ${CARDS}/var/{lock,log,mail,run,spool}
mkdir -p ${CARDS}/var/{opt,cache,lib/{misc,locate},local}
install -d -m 0750 ${CARDS}/root
install -d -m 1777 ${CARDS}{/var,}/tmp
install -d ${CARDS}/etc/init.d
mkdir -p ${CARDS}/usr/{,local/}{bin,include,lib{,64},sbin,src}
mkdir -p ${CARDS}/usr/{,local/}share/{doc,info,locale,man}
mkdir -p ${CARDS}/usr/{,local/}share/{misc,terminfo,zoneinfo}
mkdir -p ${CARDS}/usr/{,local/}share/man/man{1,2,3,4,5,6,7,8}
for dir in ${CARDS}/usr{,/local}; do
    ln -s share/{man,doc,info} ${dir}
done

install -d ${CARDS}/cross-tools{,/bin} # Create directory for cross-compilation toolchain
ln -sf ../proc/mounts ${CARDS}/etc/mtab # Maintain list of mounted filesystems

# Create root user account
cat > ${CARDS}/etc/passwd << "EOF"
root::0:0:root:/root:/bin/ash
EOF

# Create /etc/group
cat > ${CARDS}/etc/group << "EOF"
root:x:0:
bin:x:1:
sys:x:2:
kmem:x:3:
tty:x:4:
daemon:x:6:
disk:x:8:
dialout:x:10:
video:x:12:
utmp:x:13:
usb:x:14:
EOF

# Create /etc/fstab
cat > ${CARDS}/etc/fstab << "EOF"
# file system  mount-point  type   options          dump  fsck
#                                                         order

rootfs          /               auto    defaults        1      1
proc            /proc           proc    defaults        0      0
sysfs           /sys            sysfs   defaults        0      0
devpts          /dev/pts        devpts  gid=4,mode=620  0      0
tmpfs           /dev/shm        tmpfs   defaults        0      0
EOF

# Create /etc/profile (for Almquist shell)
cat > ${CARDS}/etc/profile << "EOF"
export PATH=/bin:/usr/bin

if [ `id -u` -eq 0 ] ; then
        PATH=/bin:/sbin:/usr/bin:/usr/sbin
        unset HISTFILE
fi


# Set up some environment variables.
export USER=`id -un`
export LOGNAME=$USER
export HOSTNAME=`/bin/hostname`
export HISTSIZE=1000
export HISTFILESIZE=1000
export PAGER='/bin/more '
export EDITOR='/bin/vi'
EOF

echo "Cards" > ${CARDS}/etc/HOSTNAME # Create default PC hostname

# Create login prompt message
cat > ${CARDS}/etc/issue<< "EOF"
Cards
Kernel \r on an \m

\U logged in at \t on \d
EOF

# Define BusyBox init process
cat > ${CARDS}/etc/inittab<< "EOF"
::sysinit:/etc/rc.d/startup

tty1::respawn:/sbin/getty 38400 tty1
tty2::respawn:/sbin/getty 38400 tty2
tty3::respawn:/sbin/getty 38400 tty3
tty4::respawn:/sbin/getty 38400 tty4
tty5::respawn:/sbin/getty 38400 tty5
tty6::respawn:/sbin/getty 38400 tty6

::shutdown:/etc/rc.d/shutdown
::ctrlaltdel:/sbin/reboot
EOF

# Setup mdev for BusyBox
cat > ${CARDS}/etc/mdev.conf<< "EOF"
# Devices:
# Syntax: %s %d:%d %s
# devices user:group mode

# null does already exist; therefore ownership has to
# be changed with command
null    root:root 0666  @chmod 666 $MDEV
zero    root:root 0666
grsec   root:root 0660
full    root:root 0666

random  root:root 0666
urandom root:root 0444
hwrandom root:root 0660

# console does already exist; therefore ownership has to
# be changed with command
console root:tty 0600 @mkdir -pm 755 fd && cd fd && for x in 0 1 2 3 ; do ln -sf /proc/self/fd/$x $x; done

kmem    root:root 0640
mem     root:root 0640
port    root:root 0640
ptmx    root:tty 0666

# ram.*
ram([0-9]*)     root:disk 0660 >rd/%1
loop([0-9]+)    root:disk 0660 >loop/%1
sd[a-z].*       root:disk 0660 */lib/mdev/usbdisk_link
hd[a-z][0-9]*   root:disk 0660 */lib/mdev/ide_links

tty             root:tty 0666
tty[0-9]        root:root 0600
tty[0-9][0-9]   root:tty 0660
ttyO[0-9]*      root:tty 0660
pty.*           root:tty 0660
vcs[0-9]*       root:tty 0660
vcsa[0-9]*      root:tty 0660

ttyLTM[0-9]     root:dialout 0660 @ln -sf $MDEV modem
ttySHSF[0-9]    root:dialout 0660 @ln -sf $MDEV modem
slamr           root:dialout 0660 @ln -sf $MDEV slamr0
slusb           root:dialout 0660 @ln -sf $MDEV slusb0
fuse            root:root  0666

# misc stuff
agpgart         root:root 0660  >misc/
psaux           root:root 0660  >misc/
rtc             root:root 0664  >misc/

# input stuff
event[0-9]+     root:root 0640 =input/
ts[0-9]         root:root 0600 =input/

# v4l stuff
vbi[0-9]        root:video 0660 >v4l/
video[0-9]      root:video 0660 >v4l/

# load drivers for usb devices
usbdev[0-9].[0-9]       root:root 0660 */lib/mdev/usbdev
usbdev[0-9].[0-9]_.*    root:root 0660
EOF

# Create GRUB configuration
cat > ${CARDS}/boot/grub/grub.cfg<< "EOF"

set default=0
set timeout=5

set root=(hd0,1)

menuentry "Cards" {
        linux   /boot/vmlinuz-${LINUX_VERSION} root=/dev/sda1 ro quiet
}
EOF

# Create log files
touch ${CARDS}/var/run/utmp ${CARDS}/var/log/{btmp,lastlog,wtmp}
chmod 664 ${CARDS}/var/run/utmp ${CARDS}/var/log/lastlog

# TODO: Download kernel, uncompress tarball, change directory into it
wget https://git.kernel.org/torvalds/t/linux-${LINUX_VERSION}.tar.gz -q > /dev/null
tar -xf linux-${LINUX_VERSION}.tar.gz
cd linux-${LINUX_VERSION}
# Install kernel's standard header files
make mrproper
make ARCH=${CARDS_ARCH} headers_check && \
make ARCH=${CARDS_ARCH} INSTALL_HDR_PATH=dest headers_install
cp -r dest/include/* ${CARDS}/usr/include
cd ../

# TODO: Download Binutils, uncompress tarball
wget https://ftp.gnu.org/gnu/binutils/binutils-${BINUTILS_VERSION}.tar.gz -q > /dev/null
tar -xf binutils-${BINUTILS_VERSION}.tar.gz
# Binutils is needed to handle compiled object files
mkdir binutils-build
cd binutils-build/
../binutils-${BINUTILS_VERSION}/configure --prefix=${CARDS}/cross-tools \
--target=${CARDS_TARGET} --with-sysroot=${CARDS} \
--disable-nls --enable-shared --disable-multilib
make configure-host && make
ln -s lib ${CARDS}/cross-tools/lib64
make install
cp ../binutils-${BINUTILS_VERSION}/include/libiberty.h ${CARDS}/usr/include
cd ../

# TODO: Download GCC, uncompress tarball
wget https://ftp.gnu.org/gnu/gcc/gcc-${GCC_VERSION}/gcc-${GCC_VERSION}.tar.gz -q > /dev/null
wget https://ftp.gnu.org/gnu/gmp/gmp-${GMP_VERSION}.tar.bz2 -q > /dev/null
wget https://ftp.gnu.org/gnu/mpfr/mpfr-${MPFR_VERSION}.tar.xz -q > /dev/null
wget https://ftp.gnu.org/gnu/mpc/mpc-${MPC_VERSION}.tar.gz -q > /dev/null
tar xf gcc-${GCC_VERSION}.tar.gz
# Building a statically compiled toolchain to later build glibc, which will later link to GCC cross compiler
tar xjf gmp-${GMP_VERSION}.tar.bz2
mv gmp-${GMP_VERSION} gcc-${GCC_VERSION}/gmp
tar xJf mpfr-${MPFR_VERSION}.tar.xz
mv mpfr-${MPFR_VERSION} gcc-${GCC_VERSION}/mpfr
tar xzf mpc-${MPC_VERSION}.tar.gz
mv mpc-${MPC_VERSION} gcc-${GCC_VERSION}/mpc
mkdir gcc-static
cd gcc-static/
AR=ar LDFLAGS="-Wl,-rpath,${CARDS}/cross-tools/lib" \
../gcc-${GCC_VERSION}/configure --prefix=${CARDS}/cross-tools \
--build=${CARDS_HOST} --host=${CARDS_HOST} \
--target=${CARDS_TARGET} \
--with-sysroot=${CARDS}/target --disable-nls \
--disable-shared \
--with-mpfr-include=$(pwd)/../gcc-${GCC_VERSION}/mpfr/src \
--with-mpfr-lib=$(pwd)/mpfr/src/.libs \
--without-headers --with-newlib --disable-decimal-float \
--disable-libgomp --disable-libmudflap --disable-libssp \
--disable-threads --enable-languages=c,c++ \
--disable-multilib --with-arch=${CARDS_CPU}
make all-gcc all-target-libgcc && \
make install-gcc install-target-libgcc
ln -s libgcc.a `${CARDS_TARGET}-gcc -print-libgcc-file-name | sed 's/libgcc/&_eh/'`
cd ../

# TODO: Download glibc, uncompress tarball
wget https://ftp.gnu.org/gnu/glibc/glibc-ports-${GLIBC_VERSION}.tar.gz -q > /dev/null
tar -xf glibc-ports-${GLIBC_VERSION}.tar.gz
mkdir glibc-build
cd glibc-build/
echo "libc_cv_forced_unwind=yes" > config.cache
echo "libc_cv_c_cleanup=yes" >> config.cache
echo "libc_cv_ssp=no" >> config.cache
echo "libc_cv_ssp_strong=no" >> config.cache
BUILD_CC="gcc" CC="${CARDS_TARGET}-gcc" \
AR="${CARDS_TARGET}-ar" \
RANLIB="${CARDS_TARGET}-ranlib" CFLAGS="-O2" \
../glibc-${GLIBC_VERSION}/configure --prefix=/usr \
--host=${CARDS_TARGET} --build=${CARDS_HOST} \
--disable-profile --enable-add-ons --with-tls \
--enable-kernel=2.6.32 --with-__thread \
--with-binutils=${CARDS}/cross-tools/bin \
--with-headers=${CARDS}/usr/include \
--cache-file=config.cache
make && make install_root=${CARDS}/ install
cd ../

# Building the final GCC cross compiler
mkdir gcc-build
cd gcc-build/
AR=ar LDFLAGS="-Wl,-rpath,${CARDS}/cross-tools/lib" \
../gcc-${GCC_VERSION}/configure --prefix=${CARDS}/cross-tools \
--build=${CARDS_HOST} --target=${CARDS_TARGET} \
--host=${CARDS_HOST} --with-sysroot=${CARDS} \
--disable-nls --enable-shared \
--enable-languages=c,c++ --enable-c99 \
--enable-long-long \
--with-mpfr-include=$(pwd)/../gcc-${GCC_VERSION}/mpfr/src \
--with-mpfr-lib=$(pwd)/mpfr/src/.libs \
--disable-multilib --with-arch=${CARDS_CPU}
make && make install
cp ${CARDS}/cross-tools/${CARDS_TARGET}/lib64/libgcc_s.so.1 ${CARDS}/lib64
cd ../


# TODO: Download BusyBox, uncompress tarball, change directory into it
wget https://www.busybox.net/downloads/busybox-${BUSYBOX_VERSION}.tar.bz2 -q > /dev/null
tar -xjf busybox-${BUSYBOX_VERSION}.tar.bz2
cd busybox-${BUSYBOX_VERSION}
# BusyBox coreutils
make CROSS_COMPILE="${CARDS_TARGET}-" defconfig # Use default utilities and libraries
make CROSS_COMPILE="${CARDS_TARGET}-"
make CROSS_COMPILE="${CARDS_TARGET}-" \
CONFIG_PREFIX="${CARDS}" install
cp examples/depmod.pl ${CARDS}/cross-tools/bin # Install Perl script that will be used to build kernel later

# TODO: Change into Linux kernel directory
cd linux-${LINUX_VERSION}
make ARCH=${CARDS_ARCH} \
CROSS_COMPILE=${CARDS_TARGET}- x86_64_defconfig # Default x86-64 configuration template
make ARCH=${CARDS_ARCH} \
CROSS_COMPILE=${CARDS_TARGET}- silentoldconfig # Same configuration as host machine's kernel, but with silently updated dependencies

# Compile and install kernel
make ARCH=${CARDS_ARCH} \
CROSS_COMPILE=${CARDS_TARGET}-
make ARCH=${CARDS_ARCH} \
CROSS_COMPILE=${CARDS_TARGET}- \
INSTALL_MOD_PATH=${CARDS} modules_install

# Copy files into GRUB boot folder
cp arch/x86/boot/bzImage ${CARDS}/boot/vmlinuz-${LINUX_VERSION}
cp System.map ${CARDS}/boot/System.map-${LINUX_VERSION}
cp .config ${CARDS}/boot/config-${LINUX_VERSION}

# Run BusyBox's Perl script
${CARDS}/cross-tools/bin/depmod.pl \
-F ${CARDS}/boot/System.map-${LINUX_VERSION} \
-b ${CARDS}/lib/modules/${LINUX_VERSION}
cd ../

# TODO: Download Cross-LFS bootscripts, uncompress tarball, change directory into it
wget http://ftp.osuosl.org/pub/clfs/conglomeration/bootscripts-cross-lfs/boot-scripts-cross-lfs-${CLFS_BOOTSCRIPTS_VERSION}.tar.xz -q > /dev/null
tar -xJf boot-scripts-cross-lfs-${CLFS_BOOTSCRIPTS_VERSION}.tar.xz
cd boot-scripts-cross-lfs-${CLFS_BOOTSCRIPTS_VERSION}
make DESTDIR=${CARDS}/ install-bootscripts
ln -s ../rc.d/startup ${CARDS}/etc/init.d/rcS
cd ../

# TODO: Download Pacman source tarball, uncompress tarball, change directory into it
wget https://sources.archlinux.org/other/pacman/pacman-${PACMAN_VERSION}.tar.gz -q > /dev/null
tar -xf pacman-${PACMAN_VERSION}.tar.gz
cd pacman-${PACMAN_VERSION}
./configure
make && make DESTDIR=${CARDS}/ install
cd ../

# Create final build
cp -rf ${CARDS}/ ${CARDS}-copy # Create a copy of the original build

# Remove unneeded directories
rm -rf ${CARDS}-copy/cross-tools
rm -rf ${CARDS}-copy/usr/src/*

# Remove unneeded statically compiled library files
FILES="$(ls ${CARDS}-copy/usr/lib64/*.a)"
for file in $FILES; do
    rm -f $file
done

# Remove debug symbols from binaries
find ${CARDS}-copy/{,usr/}{bin,lib,sbin} -type f -exec sudo strip --strip-debug '{}' ';'
find ${CARDS}-copy/{,usr/}lib64 -type f -exec sudo strip --strip-debug '{}' ';'

# Change file permissions, create nodes
sudo chown -R root:root ${CARDS}-copy
sudo chgrp 13 ${CARDS}-copy/var/run/utmp ${CARDS}-copy/var/log/lastlog
sudo mknod -m 0666 ${CARDS}-copy/dev/null c 1 3
sudo mknod -m 0600 ${CARDS}-copy/dev/console c 5 1
sudo chmod 4755 ${CARDS}-copy/bin/busybox

# Create final disk image
cd ${CARDS}-copy/
sudo mkisofs -J -r -o cards.iso .
