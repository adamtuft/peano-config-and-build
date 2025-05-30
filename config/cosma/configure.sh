./configure \
    --enable-exahype \
    --enable-blockstructured \
    --enable-loadbalancing \
    --enable-particles\
    --with-mpi=mpiicpc \
    --with-multithreading=omp \
    CC=icx \
    CXX=icpx \
    CXXFLAGS="-std=c++20 -qopenmp -funroll-loops -Ofast $OTTER_CXXFLAGS" \
    LIBS="$OTTER_LIBS" \
    $OTTER_FLAG
