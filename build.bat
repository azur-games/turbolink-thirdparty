@echo off
SETLOCAL
:: set TL_LIBRARIES_PATH = F:\
:: echo %TL_LIBRARIES_PATH%


set NDK_CMAKE_VERSION=3.10.2.4988404
set UE_THIRD_PARTY_PATH=D:\CustomUE5\Engine\Source\ThirdParty
set TL_LIBRARIES_PATH=%cd%
echo %TL_LIBRARIES_PATH%
cd %TL_LIBRARIES_PATH%/Source/abseil/abseil-20230125
git apply --whitespace=nowarn ../patch/diff-base-on-2023_01_25.patch

mkdir %TL_LIBRARIES_PATH%\_build\win64\abseil & cd %TL_LIBRARIES_PATH%\_build\win64\abseil

cmake -G "Visual Studio 17 2022" ^
 -DCMAKE_INSTALL_PREFIX=%TL_LIBRARIES_PATH%/output/abseil ^
 -DCMAKE_INSTALL_LIBDIR="lib/win64/$<$<CONFIG:RelWithDebInfo>:RelWithDebInfo>$<$<CONFIG:Release>:Release>" ^
 -DCMAKE_INSTALL_CMAKEDIR=lib/win64/cmake -DCMAKE_CXX_STANDARD=17 ^
 -DBUILD_TESTING=False -DABSL_PROPAGATE_CXX_STD=True ^
 %TL_LIBRARIES_PATH%/Source/abseil/abseil-20230125
cmake --build . --target INSTALL --config RelWithDebInfo --parallel
cmake --build . --target INSTALL --config Release --parallel

echo "Build Re"

cd %TL_LIBRARIES_PATH%/Source/re2/re2-20220601
git apply --whitespace=nowarn ../patch/diff-base-on-20220601.patch

mkdir %TL_LIBRARIES_PATH%\_build\win64\re2 & cd %TL_LIBRARIES_PATH%\_build\win64\re2
cmake -G "Visual Studio 17 2022" ^
 -DCMAKE_INSTALL_PREFIX=%TL_LIBRARIES_PATH%/output/re2 ^
 -DCMAKE_INSTALL_LIBDIR="lib/win64/$<$<CONFIG:RelWithDebInfo>:RelWithDebInfo>$<$<CONFIG:Release>:Release>" ^
 -DCMAKE_INSTALL_CMAKEDIR=lib/win64/cmake ^
 %TL_LIBRARIES_PATH%/Source/re2/re2-20220601
cmake --build . --target INSTALL --config RelWithDebInfo --parallel
cmake --build . --target INSTALL --config Release --parallel






echo "Build Protobuf"

cd %TL_LIBRARIES_PATH%/Source/protobuf/protobuf-4.23.x
git apply --whitespace=nowarn ../patch/diff-base-on-4.23.patch

mkdir %TL_LIBRARIES_PATH%\_build\win64\protobuf & cd %TL_LIBRARIES_PATH%\_build\win64\protobuf
cmake -G "Visual Studio 17 2022" ^
 -DCMAKE_INSTALL_PREFIX=%TL_LIBRARIES_PATH%/output/protobuf ^
 -DCMAKE_MSVC_RUNTIME_LIBRARY="MultiThreaded$<$<CONFIG:Debug>:Debug>DLL" ^
 -Dprotobuf_BUILD_TESTS=false -Dprotobuf_WITH_ZLIB=false ^
 -Dprotobuf_DEBUG_POSTFIX="" ^
 -DCMAKE_INSTALL_LIBDIR="lib/win64/$<$<CONFIG:RelWithDebInfo>:RelWithDebInfo>$<$<CONFIG:Release>:Release>" ^
 -DCMAKE_INSTALL_CMAKEDIR=lib/win64/cmake ^
 -Dprotobuf_MSVC_STATIC_RUNTIME=false ^
 -Dprotobuf_ABSL_PROVIDER=package -Dabsl_DIR="%TL_LIBRARIES_PATH%/output/abseil/lib/win64/cmake" ^
 %TL_LIBRARIES_PATH%/Source/protobuf/protobuf-4.23.x
cmake --build . --target INSTALL --config RelWithDebInfo --parallel
cmake --build . --target INSTALL --config Release --parallel



 

 echo "Build gRCP"
 
cd %TL_LIBRARIES_PATH%/Source/grpc/grpc-1.57
git apply --whitespace=nowarn  ../patch/diff-base-on-1.57.patch


mkdir %TL_LIBRARIES_PATH%\_build\win64\grpc & cd %TL_LIBRARIES_PATH%\_build\win64\grpc
cmake -G "Visual Studio 17 2022" ^
 -DCMAKE_INSTALL_PREFIX=%TL_LIBRARIES_PATH%/output/grpc ^
 -DgRPC_INSTALL_LIBDIR="lib/win64/$<$<CONFIG:RelWithDebInfo>:RelWithDebInfo>$<$<CONFIG:Release>:Release>" ^
 -DgRPC_INSTALL_CMAKEDIR=lib/win64/cmake -DgRPC_USE_CARES=OFF -DCMAKE_CXX_STANDARD=17 ^
 -DgRPC_ABSL_PROVIDER=package -Dabsl_DIR="%TL_LIBRARIES_PATH%/output/abseil/lib/win64/cmake" ^
 -DgRPC_RE2_PROVIDER=package -Dre2_DIR="%TL_LIBRARIES_PATH%/output/re2/lib/win64/cmake" ^
 -DgRPC_PROTOBUF_PROVIDER=package -DProtobuf_DIR="%TL_LIBRARIES_PATH%/output/protobuf/lib/win64/cmake" ^
 -Dutf8_range_DIR="%TL_LIBRARIES_PATH%/output/protobuf/lib/win64/cmake" ^
 -DgRPC_ZLIB_PROVIDER=package ^
 -DZLIB_INCLUDE_DIR="%UE_THIRD_PARTY_PATH%/zlib/v1.2.8/include/Win64/VS2015" ^
 -DZLIB_LIBRARY_RELEASE="%UE_THIRD_PARTY_PATH%/zlib/v1.2.8/lib/Win64/VS2015/Release/zlibstatic.lib" ^
 -DZLIB_LIBRARY_DEBUG="%UE_THIRD_PARTY_PATH%/zlib/v1.2.8/lib/Win64/VS2015/Debug/zlibstatic.lib" ^
 -DgRPC_SSL_PROVIDER=package ^
 -DOPENSSL_INCLUDE_DIR="%UE_THIRD_PARTY_PATH%/OpenSSL/1.1.1k/include/Win64/VS2015" ^
 -DLIB_EAY_LIBRARY_DEBUG="%UE_THIRD_PARTY_PATH%/OpenSSL/1.1.1k/lib/Win64/VS2015/Debug/libcrypto.lib" ^
 -DLIB_EAY_LIBRARY_RELEASE="%UE_THIRD_PARTY_PATH%/OpenSSL/1.1.1k/lib/Win64/VS2015/Release/libcrypto.lib" ^
 -DLIB_EAY_DEBUG="%UE_THIRD_PARTY_PATH%/OpenSSL/1.1.1k/lib/Win64/VS2015/Debug/libcrypto.lib" ^
 -DLIB_EAY_RELEASE="%UE_THIRD_PARTY_PATH%/OpenSSL/1.1.1k/lib/Win64/VS2015/Release/libcrypto.lib" ^
 -DSSL_EAY_DEBUG="%UE_THIRD_PARTY_PATH%/OpenSSL/1.1.1k/lib/Win64/VS2015/Debug/libssl.lib" ^
 -DSSL_EAY_LIBRARY_DEBUG="%UE_THIRD_PARTY_PATH%/OpenSSL/1.1.1k/lib/Win64/VS2015/Debug/libssl.lib" ^
 -DSSL_EAY_LIBRARY_RELEASE="%UE_THIRD_PARTY_PATH%/OpenSSL/1.1.1k/lib/Win64/VS2015/Release/libssl.lib" ^
 -DSSL_EAY_RELEASE="%UE_THIRD_PARTY_PATH%/OpenSSL/1.1.1k/lib/Win64/VS2015/Release/libssl.lib" ^
 %TL_LIBRARIES_PATH%/Source/grpc/grpc-1.57
cmake --build . --target INSTALL --config RelWithDebInfo --parallel
cmake --build . --target INSTALL --config Release --parallel



ENDLOCAL