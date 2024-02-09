@echo off
SETLOCAL
:: set TL_LIBRARIES_PATH = F:\
:: echo %TL_LIBRARIES_PATH%

set LINUX_MULTIARCH_ROOT=C:\UnrealToolchains\v20_clang-13.0.1-centos7


set NINJA_EXE_PATH=ninja

set NDK_CMAKE_VERSION=3.10.2.4988404
set UE_THIRD_PARTY_PATH=D:/CustomUE5/Engine/Source/ThirdParty
set TL_LIBRARIES_PATH=%cd%
echo %TL_LIBRARIES_PATH%

cd %TL_LIBRARIES_PATH%/Source/abseil/abseil-20230125
git apply --whitespace=nowarn ../patch/diff-base-on-2023_01_25.patch

mkdir %TL_LIBRARIES_PATH%\_build\linux\abseil & cd %TL_LIBRARIES_PATH%\_build\linux\abseil
cmake -G "Ninja Multi-Config" -DCMAKE_MAKE_PROGRAM=%NINJA_EXE_PATH% ^
 -DCMAKE_SKIP_RPATH=ON ^
 -DCMAKE_POSITION_INDEPENDENT_CODE=ON ^
 -DCMAKE_TOOLCHAIN_FILE="%TL_LIBRARIES_PATH%\BuildTools\linux\ue5-linux-cross-compile.cmake" ^
 -DUE_THIRD_PARTY_PATH=%UE_THIRD_PARTY_PATH% ^
 -DCMAKE_INSTALL_PREFIX=%TL_LIBRARIES_PATH%/output/abseil ^
 -DCMAKE_INSTALL_LIBDIR="lib/linux/$<$<CONFIG:Debug>:Debug>$<$<CONFIG:Release>:Release>" ^
 -DCMAKE_INSTALL_CMAKEDIR=lib/linux/cmake -DCMAKE_CXX_STANDARD=17 ^
 -DBUILD_TESTING=False -DABSL_PROPAGATE_CXX_STD=false ^
 %TL_LIBRARIES_PATH%/Source/abseil/abseil-20230125
cmake --build . --target install --config Debug
cmake --build . --target install --config Release

pause


echo "Build Re"

cd %TL_LIBRARIES_PATH%/Source/re2/re2-20220601
git apply --whitespace=nowarn ../patch/diff-base-on-20220601.patch

mkdir %TL_LIBRARIES_PATH%\_build\linux\re2 & cd %TL_LIBRARIES_PATH%\_build\linux\re2
cmake -G "Ninja Multi-Config" -DCMAKE_MAKE_PROGRAM=%NINJA_EXE_PATH% ^
 -DCMAKE_SKIP_RPATH=ON ^
 -DCMAKE_POSITION_INDEPENDENT_CODE=ON ^
 -DCMAKE_TOOLCHAIN_FILE="%TL_LIBRARIES_PATH%\BuildTools\linux\ue5-linux-cross-compile.cmake" ^
 -DUE_THIRD_PARTY_PATH=%UE_THIRD_PARTY_PATH% ^
 -DCMAKE_INSTALL_PREFIX=%TL_LIBRARIES_PATH%/output/re2 ^
 -DCMAKE_INSTALL_LIBDIR="lib/linux/$<$<CONFIG:Debug>:Debug>$<$<CONFIG:Release>:Release>" ^
 -DCMAKE_INSTALL_CMAKEDIR=lib/linux/cmake -DCMAKE_CXX_STANDARD=17 ^
 -DRE2_BUILD_TESTING=OFF ^
 %TL_LIBRARIES_PATH%/Source/re2/re2-20220601
cmake --build . --target install --config Debug --parallel
cmake --build . --target install --config Release --parallel

pause

echo "Build Protobuf"

cd %TL_LIBRARIES_PATH%/Source/protobuf/protobuf-4.23.x
git apply --whitespace=nowarn ../patch/diff-base-on-4.23.patch

mkdir %TL_LIBRARIES_PATH%\_build\linux\protobuf & cd %TL_LIBRARIES_PATH%\_build\linux\protobuf
cmake -G "Ninja Multi-Config" -DCMAKE_MAKE_PROGRAM=%NINJA_EXE_PATH% ^
 -DCMAKE_SKIP_RPATH=ON ^
 -DCMAKE_POSITION_INDEPENDENT_CODE=ON ^
 -DCMAKE_TOOLCHAIN_FILE="%TL_LIBRARIES_PATH%\BuildTools\linux\ue5-linux-cross-compile.cmake" ^
 -DUE_THIRD_PARTY_PATH=%UE_THIRD_PARTY_PATH% -Dprotobuf_DEBUG_POSTFIX="" ^
 -DCMAKE_INSTALL_PREFIX=%TL_LIBRARIES_PATH%/output/protobuf ^
 -DCMAKE_INSTALL_LIBDIR="lib/linux/$<$<CONFIG:Debug>:Debug>$<$<CONFIG:Release>:Release>" ^
 -DCMAKE_INSTALL_CMAKEDIR=lib/linux/cmake -DCMAKE_CXX_STANDARD=17 ^
 -Dprotobuf_BUILD_TESTS=false -Dprotobuf_WITH_ZLIB=false ^
 -Dprotobuf_BUILD_EXAMPLES=false ^
 -Dprotobuf_BUILD_PROTOC_BINARIES=false -Dprotobuf_BUILD_LIBPROTOC=false ^
 -Dprotobuf_ABSL_PROVIDER=package -Dabsl_DIR="%TL_LIBRARIES_PATH%/output/abseil/lib/linux/cmake" ^
 %TL_LIBRARIES_PATH%/Source/protobuf/protobuf-4.23.x
cmake --build . --target install --config Debug
cmake --build . --target install --config Release

pause

echo "Build gRCP"

cd %TL_LIBRARIES_PATH%/Source/grpc/grpc-1.57
git apply --whitespace=nowarn  ../patch/diff-base-on-1.57.patch
 
mkdir %TL_LIBRARIES_PATH%\_build\linux\grpc & cd %TL_LIBRARIES_PATH%\_build\linux\grpc
cmake -G "Ninja Multi-Config" -DCMAKE_MAKE_PROGRAM=%NINJA_EXE_PATH% ^
 -DCMAKE_SKIP_RPATH=ON ^
 -DCMAKE_POSITION_INDEPENDENT_CODE=ON ^
 -DCMAKE_TOOLCHAIN_FILE="%TL_LIBRARIES_PATH%\BuildTools\linux\ue5-linux-cross-compile.cmake" ^
 -DUE_THIRD_PARTY_PATH=%UE_THIRD_PARTY_PATH% -DCMAKE_CXX_STANDARD=17 ^
 -DCMAKE_INSTALL_PREFIX=%TL_LIBRARIES_PATH%/output/grpc ^
 -DgRPC_INSTALL_LIBDIR="lib/linux/$<$<CONFIG:Debug>:Debug>$<$<CONFIG:Release>:Release>" ^
 -DgRPC_INSTALL_CMAKEDIR=lib/linux/cmake -DCMAKE_CXX_STANDARD=17 ^
 -DgRPC_ABSL_PROVIDER=package -Dabsl_DIR="%TL_LIBRARIES_PATH%/output/abseil/lib/linux/cmake" ^
 -DgRPC_USE_CARES=OFF ^
 -DgRPC_RE2_PROVIDER=package -Dre2_DIR="%TL_LIBRARIES_PATH%/output/re2/lib/linux/cmake" ^
 -DgRPC_PROTOBUF_PROVIDER=package ^
 -DProtobuf_DIR="%TL_LIBRARIES_PATH%/output/protobuf/lib/linux/cmake" ^
 -Dutf8_range_DIR="%TL_LIBRARIES_PATH%/output/protobuf/lib/linux/cmake" ^
 -DgRPC_ZLIB_PROVIDER=package ^
 -DZLIB_INCLUDE_DIR="%UE_THIRD_PARTY_PATH%/zlib/v1.2.8/include/Unix/x86_64-unknown-linux-gnu" ^
 -DZLIB_LIBRARY_RELEASE="%UE_THIRD_PARTY_PATH%/zlib/v1.2.8/lib/Unix/x86_64-unknown-linux-gnu/libz.a" ^
 -DZLIB_LIBRARY_DEBUG="%UE_THIRD_PARTY_PATH%/zlib/v1.2.8/lib/Unix/x86_64-unknown-linux-gnu/libz.a" ^
 -DgRPC_SSL_PROVIDER=package ^
 -DOPENSSL_INCLUDE_DIR="%UE_THIRD_PARTY_PATH%\\OpenSSL\\1.1.1c\\include\\Unix\\x86_64-unknown-linux-gnu" ^
 -DOPENSSL_SSL_LIBRARY="%UE_THIRD_PARTY_PATH%/OpenSSL/1.1.1с/lib/Unix/x86_64-unknown-linux-gnu/libssl.a" ^
 -DOPENSSL_CRYPTO_LIBRARY="%UE_THIRD_PARTY_PATH%/OpenSSL/1.1.1с/lib/Unix/x86_64-unknown-linux-gnu/libcrypto.a" ^
 -DgRPC_BUILD_CODEGEN=OFF -DgRPC_BUILD_CSHARP_EXT=OFF ^
 -DgRPC_BUILD_GRPC_CPP_PLUGIN=OFF -DgRPC_BUILD_GRPC_CSHARP_PLUGIN=OFF ^
 -DgRPC_BUILD_GRPC_NODE_PLUGIN=OFF -DgRPC_BUILD_GRPC_OBJECTIVE_C_PLUGIN=OFF ^
 -DgRPC_BUILD_GRPC_PHP_PLUGIN=OFF -DgRPC_BUILD_GRPC_PYTHON_PLUGIN=OFF ^
 -DgRPC_BUILD_GRPC_RUBY_PLUGIN=OFF ^
 %TL_LIBRARIES_PATH%/Source/grpc/grpc-1.57
cmake --build . --target install --config Debug
cmake --build . --target install --config Release


ENDLOCAL