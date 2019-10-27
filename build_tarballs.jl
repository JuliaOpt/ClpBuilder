# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder

# To propose an update to the Clp binaries please follow these steps:
# 1) Fork this ClpBuilder repository and create a new branch
# 2) Modify the build script (e.g., changing the portion marked by START/END-EASY-CHANGE-BLOCK) and test that it compiles 
#    for all architectures by running `julia --color=yes build_tarballs.jl --verbose`. (Note that this build make take a 
#    long time. Also, adding the --debug argument to the command will drop you into the build environment for debugging)
# 3) Create a github release in your fork of ClpBuilder with the generated tarballs and build_ClpBuilder.vX.X.X.jl
#    (https://github.com/tcnksm/ghr is usefull to automate this release creation)
# 4) Fork the Clp.jl repository (https://github.com/JuliaOpt/Clp.jl) and create a new branch
# 5) Update the portion marked by ## START-VERSION-UPDATE-BLOCK / ## END-VERSION-UPDATE-BLOCK in Clp.jl/deps/build.jl
#    on your branch of Clp.jl with the corresponding lines in the build_ClpBuilder.vX.X.X.jl file you generated in steps 2)/3)
# 6) Check that tests pass on your branch of Clp (e.g. `]test Clp`)
# 7) Create a PR for ClpBuilder.jl (No need to create a PR for Clp.jl)


# Ideally, any update would need changes only on the EASY-CHANGE-BLOCK below
# Note that if two sources have the same version then they need to have
# different extension so that the corresponding filenames are different. 
# For instance, consider the following case where COINMumps and COINLapack 
# both use versio 1.6.0:
#    COINMumps_version = v"1.6.0"
#    COINMumps_extension = "tar.gz"
#    COINLapack_version = v"1.6.0"
#    COINLapack_extension = "zip"
# In this case, we need one of the libraries to use the "tar.gz" extension and 
# the other to use the "zip" extension. The reason for this is that the file names
# for github releases for COINMumps and COINLapack for the configuration above will
# be respectively `1.6.0.tar.gz` and `1.6.0.zip`. If we instead had used the same
# extensions, one of the files would have been overwritten.


##START-EASY-CHANGE-BLOCK
Clp_version = v"1.17.3"
Clp_extension = "tar.gz"
Clp_hash = "25f0692fe1daa492e7801770af6991506ae9a8c34a4cae358d017400a02dfcf8"
Osi_version = v"0.108.5"
Osi_extension = "tar.gz"
Osi_hash = "c9a6f098e2824883bb3ec1f12df5987b7a8da0f1241988a5dd4663ac362e6381"
CoinUtils_version = v"2.11.3"
CoinUtils_extension = "tar.gz"
CoinUtils_hash = "7c4753816e765974941db75ec89f8855e56b86959f3a5f068fdf95b0003be61c"
COINMumps_version = v"1.6.0"
COINMumps_extension = "tar.gz"
COINMumps_hash = "3f2bb7d13333e85a29cd2dadc78a38bbf469bc3920c4c0933a90b7d8b8dc798a"
COINMetis_version = v"1.3.5"
COINMetis_extension = "tar.gz"
COINMetis_hash = "98a6110d5d004a16ad42ee26cfac508477f44aa6fe296b90a6413fe0273ebe24"
COINLapack_version = v"1.6.0"
COINLapack_extension = "zip"
COINLapack_hash = "227969f240176c8e1f391548f8f854bf81ac13c9c3f9803b345eaa052a399b3a"
COINBLAS_version = v"1.4.6"
COINBLAS_extension = "tar.gz"
COINBLAS_hash = "f9601efb98f04fdba220d49d5bda98d2a5a5e2ed7564df339bc7149b0c303f0c"
ASL_version = v"3.1.0"
ASL_extension = "tar.gz"
ASL_hash = "587c1a88f4c8f57bef95b58a8586956145417c8039f59b1758365ccc5a309ae9"

# List of symbols that will be externally visible in the Clp library 
# List of symbols is separated by | and the true symbol names are matched 
# with a * pre- and post-appended (e.g. Clp matches *Clp*)
PRESERVE_SYMBOLS = ["Clp","maximumIterations"]
##END-EASY-CHANGE-BLOCK

name = "ClpBuilder"
# Collection of sources required to build ClpBuilder
sources = [
    "./bundled",
    "https://github.com/coin-or/Clp/archive/releases/$(Clp_version).$(Clp_extension)" =>
    Clp_hash,
    "https://github.com/coin-or/Osi/archive/releases/$(Osi_version).$(Osi_extension)" =>
    Osi_hash,
    "https://github.com/coin-or/CoinUtils/archive/releases/$(CoinUtils_version).$(CoinUtils_extension)" =>
    CoinUtils_hash,
    "https://github.com/coin-or-tools/ThirdParty-Mumps/archive/releases/$(COINMumps_version).$(COINMumps_extension)" =>
    COINMumps_hash,
    "https://github.com/coin-or-tools/ThirdParty-Metis/archive/releases/$(COINMetis_version).$(COINMetis_extension)" =>
    COINMetis_hash,
    "https://github.com/coin-or-tools/ThirdParty-Lapack/archive/releases/$(COINLapack_version).$(COINLapack_extension)" =>
    COINLapack_hash,
    "https://github.com/coin-or-tools/ThirdParty-Blas/archive/releases/$(COINBLAS_version).$(COINBLAS_extension)"  =>
    COINBLAS_hash,
    "https://github.com/ampl/mp/archive/$(ASL_version).tar.gz"  =>
    ASL_hash,
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir
set -e
### Preliminaries
# Standard BB updates
update_configure_scripts
# Fix some paths
for path in ${LD_LIBRARY_PATH//:/ }; do
    for file in $(ls $path/*.la); do
        echo "$file"
        baddir=$(sed -n "s|libdir=||p" $file)
        sed -i~ -e "s|$baddir|'$path'|g" $file
    done
done
# Osi, Cgl, Clp, CoinUtils, mumps, metis, lapack, blas, asl
if [ $target = "x86_64-apple-darwin14" ]; then
  export AR=/opt/x86_64-apple-darwin14/bin/x86_64-apple-darwin14-ar
fi
### Compile ASL
# Use staticfloat's cross-compile trick for ASL https://github.com/ampl/mp/issues/115
cd $WORKSPACE/srcdir/mp-*
rm -rf thirdparty/benchmark
patch -p1 < $WORKSPACE/srcdir/asl-extra/no_benchmark.patch
# Build ASL
mkdir build
cd build
if [ $target = "x86_64-w64-mingw32" ] || [ $target = "i686-w64-mingw32" ]; then
   cmake -DCMAKE_C_FLAGS='-fPIC -DPIC' -DBUILD_SHARED_LIBS=OFF -DCMAKE_INSTALL_PREFIX=$prefix -DCMAKE_TOOLCHAIN_FILE=/opt/$target/$target.toolchain -DRUN_HAVE_STD_REGEX=0 -DRUN_HAVE_STEADY_CLOCK=0 -DHAVE_ACCESS_DRIVER_EXITCODE=0 -DHAVE_EXCEL_DRIVER_EXITCODE=0 -DHAVE_ODBC_TEXT_DRIVER_EXITCODE=0    ../
else
   cmake -DCMAKE_C_FLAGS='-fPIC -DPIC' -DBUILD_SHARED_LIBS=OFF -DCMAKE_INSTALL_PREFIX=$prefix  -DCMAKE_TOOLCHAIN_FILE=/opt/$target/$target.toolchain       -DRUN_HAVE_STD_REGEX=0       -DRUN_HAVE_STEADY_CLOCK=0       ../
fi
# Copy over pregenerated files after building arithchk, so as to fake out cmake,
# because cmake will delete our arith.h
## If this fails it is ok, we just want to prevend cmake deleting arith.h
set +e
make arith-h VERBOSE=1
set -e
mkdir -p src/asl
cp -v $WORKSPACE/srcdir/asl-extra/expr-info.cc ../src/expr-info.cc
cp -v $WORKSPACE/srcdir/asl-extra/arith.h.${target} src/asl/arith.h
# Build and install ASL
make -j${nproc} VERBOSE=1
make install VERBOSE=1
### Compile Lapack
cd $WORKSPACE/srcdir
cd ThirdParty-Blas-releases-*/
./get.Blas
mkdir build
cd build/
# configure, make and install
../configure --prefix=$prefix --with-pic --disable-pkg-config --host=${target} --disable-shared --enable-static --enable-dependency-linking lt_cv_deplibs_check_method=pass_all
make -j${nproc}
make install
### Compile Lapack
cd $WORKSPACE/srcdir
cd ThirdParty-Lapack-releases-*/
./get.Lapack
mkdir build
cd build/
# configure, make and install
../configure --prefix=$prefix --with-pic --disable-pkg-config  --host=${target} --disable-shared --enable-static --enable-dependency-linking lt_cv_deplibs_check_method=pass_all \
--with-blas-lib="-L$prefix/lib -lcoinblas"
make -j${nproc}
make install
### Compile Metis
cd $WORKSPACE/srcdir
cd ThirdParty-Metis-releases-*/
./get.Metis
mkdir build
cd build/
# configure, make and install
../configure --prefix=$prefix --with-pic --disable-pkg-config --host=${target} --disable-shared --enable-static --enable-dependency-linking lt_cv_deplibs_check_method=pass_all
make -j${nproc}
make install
### Compile Mumps
cd $WORKSPACE/srcdir
cd ThirdParty-Mumps-releases-*/
./get.Mumps
patch -p1 < $WORKSPACE/srcdir/mumps-extra/quiet.diff
mkdir build
cd build/
# configure, make and install
../configure --prefix=$prefix --with-pic --disable-pkg-config --host=${target} --disable-shared --enable-static --enable-dependency-linking lt_cv_deplibs_check_method=pass_all \
--with-metis-lib="-L${prefix}/lib -lcoinmetis" --with-metis-incdir="$prefix/include/coin/ThirdParty" \
--with-blas-lib="-L$prefix/lib -lcoinblas"
make -j${nproc}
make install
### Compile CoinUtils
cd $WORKSPACE/srcdir
cd CoinUtils-releases-*/
mkdir build
cd build/
# Set env vars: CPPFLAGS
if [ $target = "aarch64-linux-gnu" ] || [ $target = "arm-linux-gnueabihf" ]; then
   export CPPFLAGS="-std=c++11 -D_GLIBCXX_USE_CXX11_ABI=1"
fi
# configure, make and install
../configure --prefix=$prefix --with-pic --disable-pkg-config  --host=${target} --disable-shared --enable-static --enable-dependency-linking lt_cv_deplibs_check_method=pass_all \
--with-blas-lib="-L${prefix}/lib -lcoinblas" \
--with-lapack-lib="-L${prefix}/lib -lcoinlapack"
make -j${nproc}
make install
# Clear env vars: CPPFLAGS
export CPPFLAGS=""
### Compile Osi
cd $WORKSPACE/srcdir
cd Osi-releases-*/
mkdir build
cd build/
# Set env vars: CXXFLAGS and CPPFLAGS
export CXXFLAGS="-std=c++11"
if [ $target = "aarch64-linux-gnu" ] || [ $target = "arm-linux-gnueabihf" ]; then
   export CPPFLAGS="-std=c++11"
fi
# configure, make and install
../configure --prefix=$prefix --with-pic --disable-pkg-config --host=${target} --disable-shared --enable-static --enable-dependency-linking lt_cv_deplibs_check_method=pass_all \
--with-coinutils-lib="-L${prefix}/lib -lCoinUtils" --with-coinutils-incdir="$prefix/include/coin" \
--with-lapack-lib="-L${prefix}/lib -lcoinlapack" \
--with-blas-lib="-L${prefix}/lib -lcoinblas"
make -j${nproc}
make install
# Clear env vars: CXXFLAGS and CPPFLAGS
export CXXFLAGS=""
export CPPFLAGS=""

## Compile Clp

cd $WORKSPACE/srcdir
cd Clp-releases-*/
mkdir build
cd build/

# Set env vars: CPPFLAGS
if [ $target = "aarch64-linux-gnu" ]; then
   export CPPFLAGS="-DNDEBUG -w -DCOIN_USE_MUMPS_MPI_H -D__arm__ -std=c++11 -D_GLIBCXX_USE_CXX11_ABI=1"
elif [ $target = "arm-linux-gnueabihf" ]; then
   export CPPFLAGS="-DNDEBUG -w -DCOIN_USE_MUMPS_MPI_H -D__arm__ -mfpu=neon -std=c++11 -D_GLIBCXX_USE_CXX11_ABI=1"
else
   export CPPFLAGS="-DNDEBUG -w -DCOIN_USE_MUMPS_MPI_H"
fi

# Staticly link all dependencies and export only Clp symbols
# force only exporting symbols related to Clp
sed -i~ -e 's/LT_LDFLAGS="-no-undefined"/LT_LDFLAGS="-no-undefined -export-symbols-regex \\\\"BB_PRESERVE_SYMBOLS\\\\""/g' ../configure
sed -i~ -e 's/LT_LDFLAGS="-no-undefined"/LT_LDFLAGS="-no-undefined -export-symbols-regex \\\\"BB_PRESERVE_SYMBOLS\\\\""/g' ../Clp/configure

# configure, make and install
if [ $target = "x86_64-apple-darwin14" ]; then
  # Ignore the "# Don't fix this by using the ld -exported_symbols_list flag, it doesn't exist in older darwin lds"
  # seems to work for the current version and otherwise a long list of non-Clp symbols are exported
  sed -i~ -e "s|~nmedit -s \$output_objdir/\${libname}-symbols.expsym \${lib}| -exported_symbols_list \$output_objdir/\${libname}-symbols.expsym|g" ../configure
  # fix linking issue
  export OSICLPLIB_LIBS=" -lbz2 -lz ${prefix}/lib/libcoinlapack.a ${prefix}/lib/libCoinUtils.a ${prefix}/lib/libOsi.a ${prefix}/lib/libcoinblas.a"
  ../configure --prefix=$prefix --with-pic --disable-pkg-config --host=${target} --enable-shared --enable-static  \
  --with-asl-lib="${prefix}/lib/libasl.a" --with-asl-incdir="$prefix/include/asl" \
  --with-blas-lib="${prefix}/lib/libcoinblas.a -lgfortran" \
  --with-lapack-lib="${prefix}/lib/libcoinlapack.a" \
  --with-metis-lib="${prefix}/lib/libcoinmetis.a" --with-metis-incdir="$prefix/include/coin/ThirdParty" \
  --with-mumps-lib="${prefix}/lib/libcoinmetis.a ${prefix}/lib/libcoinblas.a ${prefix}/lib/libcoinmumps.a -L/opt/x86_64-apple-darwin14/x86_64-apple-darwin14/lib -lgfortran" --with-mumps-incdir="$prefix/include/coin/ThirdParty" \
  --with-coinutils-lib="${prefix}/lib/libcoinlapack.a ${prefix}/lib/libcoinblas.a ${prefix}/lib/libCoinUtils.a -lbz2 -lz" --with-coinutils-incdir="$prefix/include/coin" \
  --with-osi-lib="${prefix}/lib/libOsi.a" --with-osi-incdir="$prefix/include/coin" \
  lt_cv_deplibs_check_method=pass_all
elif [ $target = "x86_64-w64-mingw32" ] || [ $target = "i686-w64-mingw32" ]; then 
  # fix linking issue
  export OSICLPLIB_LIBS="${prefix}/lib/libOsi.a   ${prefix}/lib/libCoinUtils.a ${prefix}/lib/libcoinlapack.a  ${prefix}/lib/libcoinblas.a  -lgfortran"
  ../configure --prefix=$prefix --with-pic --disable-pkg-config --host=${target} --enable-shared --enable-static \
  --with-asl-lib="${prefix}/lib/libasl.a" --with-asl-incdir="$prefix/include/asl" \
  --with-lapack-lib="${prefix}/lib/libcoinlapack.a" \
  --with-mumps-lib="${prefix}/lib/libcoinmumps.a -lgfortran ${prefix}/lib/libcoinmetis.a" --with-mumps-incdir="$prefix/include/coin/ThirdParty" \
  --with-metis-lib="${prefix}/lib/libcoinmetis.a" --with-metis-incdir="$prefix/include/coin/ThirdParty" \
  --with-coinutils-lib="${prefix}/lib/libCoinUtils.a ${prefix}/lib/libcoinblas.a ${prefix}/lib/libcoinlapack.a" --with-coinutils-incdir="$prefix/include/coin" \
  --with-osi-lib="${prefix}/lib/libOsi.a" --with-osi-incdir="$prefix/include/coin" \
  --with-blas-lib="${prefix}/lib/libcoinblas.a -lgfortran" \
  lt_cv_deplibs_check_method=pass_all
  # fix linking issue
  sed -i~ -e 's|libClpSolver_la_LIBADD = \$(CLPLIB_LIBS) libClp\.la|libClpSolver_la_LIBADD = $(CLPLIB_LIBS) libClp.la ${prefix}/lib/libcoinblas.a -lgfortran|g' Clp/src/Makefile
else
 ../configure --prefix=$prefix --with-pic --disable-pkg-config --host=${target} --enable-shared --enable-static \
 --with-asl-lib="${prefix}/lib/libasl.a" --with-asl-incdir="$prefix/include/asl" \
 --with-lapack-lib="${prefix}/lib/libcoinlapack.a" \
 --with-mumps-lib="${prefix}/lib/libcoinmumps.a -lgfortran ${prefix}/lib/libcoinmetis.a" --with-mumps-incdir="$prefix/include/coin/ThirdParty" \
 --with-metis-lib="${prefix}/lib/libcoinmetis.a" --with-metis-incdir="$prefix/include/coin/ThirdParty" \
 --with-coinutils-lib="${prefix}/lib/libCoinUtils.a ${prefix}/lib/libcoinblas.a ${prefix}/lib/libcoinlapack.a" --with-coinutils-incdir="$prefix/include/coin" \
 --with-osi-lib="${prefix}/lib/libOsi.a" --with-osi-incdir="$prefix/include/coin" \
 --with-blas-lib="${prefix}/lib/libcoinblas.a -lgfortran" \
 lt_cv_deplibs_check_method=pass_all LDFLAGS=-ldl;
fi

# COIN makefiles uses -retain-symbols-file in linux for symbol filtering, which does not seem to filter the dynamic table so 
# we switch to -version-script
if [ $target = "x86_64-linux-gnu" ] || [ $target = "i686-linux-gnu" ]; then 
  echo "{ global:" > $WORKSPACE/srcdir/names.ver
  echo "*BB_PRESERVE_SYMBOLS_LINUX*;" >> $WORKSPACE/srcdir/names.ver
  echo "local: *; };" >> $WORKSPACE/srcdir/names.ver
  sed -i~ -e 's/archive_expsym_cmds=.*CC.*/archive_expsym_cmds="\\$CC -shared -nostdlib \\$predep_objects \\$libobjs \\$deplibs \\$postdep_objects \\$compiler_flags \\${wl}-soname \\$wl\\$soname \\${wl}-version-script \\${wl}\\$WORKSPACE\/srcdir\/names.ver -o \\$lib"/g' libtool
fi

make -j${nproc}

# Clean-up bin directory before installing
rm ${prefix}/bin/*

# Install
make install

# Clean-up lib directory
rm ${prefix}/lib/*.a
"""
BB_PRESERVE_SYMBOLS = join(PRESERVE_SYMBOLS, raw"""\\|""") 
script = replace(script, "BB_PRESERVE_SYMBOLS" => BB_PRESERVE_SYMBOLS)
BB_PRESERVE_SYMBOLS_LINUX = join(PRESERVE_SYMBOLS, "*;*")
script = replace(script, "BB_PRESERVE_SYMBOLS_LINUX" => BB_PRESERVE_SYMBOLS_LINUX)

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = [
    Linux(:i686, libc=:glibc),
    Linux(:x86_64, libc=:glibc),
    Linux(:aarch64, libc=:glibc),
    Linux(:armv7l, libc=:glibc, call_abi=:eabihf),
    MacOS(:x86_64),
    Windows(:i686),
    Windows(:x86_64)
]
platforms = expand_gcc_versions(platforms)
# To fix gcc4 bug in Windows
platforms = setdiff(platforms, [Windows(:x86_64, compiler_abi=CompilerABI(:gcc4)), Windows(:i686, compiler_abi=CompilerABI(:gcc4))])
push!(platforms, Windows(:i686,compiler_abi=CompilerABI(:gcc6)))
push!(platforms, Windows(:x86_64,compiler_abi=CompilerABI(:gcc6)))

# It seems Clp in ARM now needs C++11, so gcc4 is not working.
# A possible fix is to switch to gcc6 as for windows, but this will require updating all dependencies below too.
platforms = setdiff(platforms, [Linux(:armv7l, libc=:glibc, call_abi=:eabihf, compiler_abi=CompilerABI(:gcc4)), Linux(:aarch64, libc=:glibc, compiler_abi=CompilerABI(:gcc4))])

# The products that we will ensure are always built
products(prefix) = [
    LibraryProduct(prefix, "libClp", :libClp),
    LibraryProduct(prefix, "libClpSolver", :libClpSolver)
]

# Dependencies that must be installed before this package can be built
dependencies = [
   # "https://github.com/JuliaOpt/OsiBuilder/releases/download/v0.107.9-1-static/build_OsiBuilder.v0.107.9.jl",
   # "https://github.com/JuliaOpt/CoinUtilsBuilder/releases/download/v2.10.14-1-static/build_CoinUtilsBuilder.v2.10.14.jl",
   # "https://github.com/JuliaOpt/COINMumpsBuilder/releases/download/v1.6.0-1-static/build_COINMumpsBuilder.v1.6.0.jl",
   # "https://github.com/JuliaOpt/COINMetisBuilder/releases/download/v1.3.5-1-static/build_COINMetisBuilder.v1.3.5.jl",
   # "https://github.com/JuliaOpt/COINLapackBuilder/releases/download/v1.5.6-1-static/build_COINLapackBuilder.v1.5.6.jl",
   # "https://github.com/JuliaOpt/COINBLASBuilder/releases/download/v1.4.6-1-static/build_COINBLASBuilder.v1.4.6.jl",
   # "https://github.com/JuliaOpt/ASLBuilder/releases/download/v3.1.0-1-static/build_ASLBuilder.v3.1.0.jl"
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, Clp_version, sources, script, platforms, products, dependencies)
