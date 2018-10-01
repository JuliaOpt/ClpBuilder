# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder

name = "ClpBuilder"
version = v"1.16.11"

# Collection of sources required to build ClpBuilder
sources = [
    "https://github.com/coin-or/Clp/archive/releases/1.16.11.tar.gz" =>
    "ac42c00ba95e1e034ae75ba0e3a5ff03b452191e0c9b2f5e2d5e65bf652fb0a1",

]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir
cd Clp-releases-1.16.11/
update_configure_scripts
# temporary fix
for path in ${LD_LIBRARY_PATH//:/ }; do
    for file in $(ls $path/*.la); do
        echo "$file"
        baddir=$(sed -n "s|libdir=||p" $file)
        sed -i~ -e "s|$baddir|'$path'|g" $file
    done
done
mkdir build
cd build/
if [ $target = "x86_64-w64-mingw32" ] || [ $target = "i686-w64-mingw32" ]; then 
export LDFLAGS="-L${prefix}/lib -lcoinglpk -lCoinUtils"
fi
export CPPFLAGS="-DCOIN_USE_MUMPS_MPI_H"
../configure --prefix=$prefix --with-pic --disable-pkg-config --host=${target} --enable-shared --disable-static \
--enable-dependency-linking lt_cv_deplibs_check_method=pass_all \
--with-asl-lib="-L${prefix}/lib -lasl" --with-asl-incdir="$prefix/include/asl" \
--with-blas="-L${prefix}/lib -lcoinblas" \
--with-lapack="-L${prefix}/lib -lcoinlapack"\
--with-metis-lib="-L${prefix}/lib -lcoinmetis" --with-metis-incdir="$prefix/include/coin/ThirdParty"\
--with-mumps-lib="-L${prefix}/lib -lcoinmumps" --with-mumps-incdir="$prefix/include/coin/ThirdParty" \
--with-glpk-lib="-L${prefix}/lib -lcoinglpk" --with-glpk-incdir="$prefix/include/coin/ThirdParty" \
--with-coinutils-lib="-L${prefix}/lib -lCoinUtils" --with-coinutils-incdir="$prefix/include/coin" \
--with-osi-lib="-L${prefix}/lib -lOsi" --with-osi-incdir="$prefix/include/coin"
make -j${nproc}
make install

"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = [
    Linux(:i686, :glibc),
    Linux(:x86_64, :glibc),
    Linux(:aarch64, :glibc),
    Linux(:armv7l, :glibc, :eabihf),
    MacOS(:x86_64),
    Windows(:i686),
    Windows(:x86_64)
]
platforms = expand_gcc_versions(platforms)

# The products that we will ensure are always built
products(prefix) = [
    LibraryProduct(prefix, "libOsiClp", :libOsiClp),
    LibraryProduct(prefix, "libClp", :libClp),
    LibraryProduct(prefix, "libClpSolver", :libClpSolver)
]

# Dependencies that must be installed before this package can be built
dependencies = [
    "https://github.com/juan-pablo-vielma/OsiBuilder/releases/download/v0.107.9-1/build_OsiBuilder.v0.107.9.jl",
    "https://github.com/juan-pablo-vielma/CoinUtilsBuilder/releases/download/v2.10.14-1/build_CoinUtilsBuilder.v2.10.14.jl",
    "https://github.com/juan-pablo-vielma/COINGLPKBuilder/releases/download/v1.10.5-1/build_COINGLPKBuilder.v1.10.5.jl",
    "https://github.com/juan-pablo-vielma/COINMumpsBuilder/releases/download/v1.6.0-1/build_COINMumpsBuilder.v1.6.0.jl",
    "https://github.com/juan-pablo-vielma/COINMetisBuilder/releases/download/v1.3.5-1/build_COINMetisBuilder.v1.3.5.jl",
    "https://github.com/juan-pablo-vielma/COINLapackBuilder/releases/download/v1.5.6-1/build_COINLapackBuilder.v1.5.6.jl",
    "https://github.com/juan-pablo-vielma/COINBLASBuilder/releases/download/v1.4.6-1/build_COINBLASBuilder.v1.4.6.jl",
    "https://github.com/juan-pablo-vielma/ASLBuilder/releases/download/v3.1.0-1/build_ASLBuilder.v3.1.0.jl"
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies)

