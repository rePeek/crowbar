default:
    @just list

build:
    cmake -B build -G Ninja -DCMAKE_BUILD_TYPE=Debug -DCMAKE_INSTALL_PREFIX=install -Dcrowbar_ENABLE_CLANG_TIDY=OFF -Dcrowbar_WARNINGS_AS_ERRORS=OFF
    cmake --build build
    cmake --install build
