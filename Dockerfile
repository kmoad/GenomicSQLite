# This Dockerfile builds libgenomicsqlite.so in an obsolete OS to maximize portability
FROM ubuntu:14.04
ARG CMAKE_VERSION=3.17.3
ARG SQLITE_VERSION=3310000
ARG ZSTD_VERSION=1.4.5
ENV CFLAGS="-march=core-avx2 -O3"
ENV CXXFLAGS=${CFLAGS}

# apt
RUN apt-get -qq update && DEBIAN_FRONTEND=noninteractive apt-get -qq install -y \
        build-essential wget zip rsync git-core

RUN mkdir -p /work/GenomicSQLite

# SQLite
WORKDIR /work
RUN wget -nv https://www.sqlite.org/2020/sqlite-amalgamation-${SQLITE_VERSION}.zip \
        && unzip -o sqlite-amalgamation-${SQLITE_VERSION}.zip
WORKDIR /work/sqlite-amalgamation-${SQLITE_VERSION}
RUN gcc -shared -o libsqlite3.so -fPIC -shared -Wl,-soname,libsqlite3.so -g ${CFLAGS} sqlite3.c
RUN cp libsqlite3.so /usr/local/lib && cp *.h /usr/local/include

# Zstandard
WORKDIR /work
RUN wget -nv -O - https://github.com/facebook/zstd/releases/download/v${ZSTD_VERSION}/zstd-${ZSTD_VERSION}.tar.gz | tar zx
WORKDIR /work/zstd-${ZSTD_VERSION}
RUN make install -j $(nproc)

# CMake
WORKDIR /work
RUN wget -nv https://github.com/Kitware/CMake/releases/download/v${CMAKE_VERSION}/cmake-${CMAKE_VERSION}-Linux-x86_64.sh
RUN yes | sh cmake-${CMAKE_VERSION}-Linux-x86_64.sh
RUN rsync -a cmake-${CMAKE_VERSION}-Linux-x86_64/ /usr/local/

# libgenomicsqlite.so
ADD . /work/GenomicSQLite
WORKDIR /work/GenomicSQLite
RUN rm -rf build && cmake -DCMAKE_BUILD_TYPE=Release -B build . && cmake --build build --target genomicsqlite -j $(nproc)
RUN ldd -v build/libgenomicsqlite.so