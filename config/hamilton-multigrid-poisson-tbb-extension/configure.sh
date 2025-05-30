./configure \
    --enable-exahype \
    --enable-blockstructured \
    --enable-loadbalancing \
    --enable-particles \
    --enable-mghype \
    --enable-finiteelements \
    --with-multithreading=tbb_extension \
    CC=icx \
    CXX=icpx \
    CXXFLAGS="-std=c++20 -qopenmp -funroll-loops -Ofast $OTTER_CXXFLAGS" \
    LDFLAGS="-L/apps/developers/libraries/tbb/2022.0/1/default/tbb/latest/lib" \
    LIBS="-ltbb $OTTER_LIBS" \
    $OTTER_FLAG
