mkdir -p ${PACKAGES}
cd ${PACKAGES}

# TODO: Download zlib source tarball, uncompress tarball, change directory into it
echo "Building zlib-${ZLIB_VERSION}"
wget https://zlib.net/zlib-${ZLIB_VERSION}.tar.xz -q > /dev/null
tar -xJf zlib-${ZLIB_VERSION}.tar.xz
cd zlib-${ZLIB_VERSION}
sed -i 's/-O3/-Os/g' configure
./configure --prefix=/usr --shared
make && make DESTDIR=${PACKAGES}/ install
cd ../

# TODO: Download Pacman source tarball, uncompress tarball, change directory into it
echo "Building pacman-${PACMAN_VERSION}"
wget https://sources.archlinux.org/other/pacman/pacman-${PACMAN_VERSION}.tar.gz -q > /dev/null
tar -xf pacman-${PACMAN_VERSION}.tar.gz
cd pacman-${PACMAN_VERSION}
./configure
make && make DESTDIR=${PACKAGES}/ install
cd ../
