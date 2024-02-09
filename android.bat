@echo off
SETLOCAL

set NDK_CMAKE_VERSION=3.10.2.4988404
set UE_THIRD_PARTY_PATH=D:\CustomUE5\Engine\Source\ThirdParty
set TL_LIBRARIES_PATH=%cd%

mkdir %TL_LIBRARIES_PATH%\_build\android\abseil & cd %TL_LIBRARIES_PATH%\_build\android\abseil

mkdir arm64-v8a
"%ANDROID_HOME%\cmake\%NDK_CMAKE_VERSION%\bin\cmake.exe" -G "Ninja" ^
 -DCMAKE_SKIP_RPATH=ON ^
 -DCMAKE_USE_RELATIVE_PATHS==ON ^
 -DCMAKE_POSITION_INDEPENDENT_CODE=ON ^
 -DCMAKE_TOOLCHAIN_FILE="%NDKROOT%\build\cmake\android.toolchain.cmake" ^
 -DCMAKE_MAKE_PROGRAM=%ANDROID_HOME%\cmake\%NDK_CMAKE_VERSION%\bin\ninja.exe ^
 -DANDROID_ABI=arm64-v8a -DANDROID_PLATFORM=android-21 -DCMAKE_CXX_STANDARD=17 ^
 -DCMAKE_INSTALL_PREFIX=%TL_LIBRARIES_PATH%/output/abseil ^
 -DCMAKE_INSTALL_LIBDIR="lib/android/arm64-v8a/$<$<CONFIG:Debug>:Debug>$<$<CONFIG:Release>:Release>" ^
 -DCMAKE_INSTALL_CMAKEDIR=lib/android/arm64-v8a/cmake -DABSL_PROPAGATE_CXX_STD=True ^
 %TL_LIBRARIES_PATH%/Source/abseil/abseil-20230125 
 ::%ANDROID_HOME%\cmake\%NDK_CMAKE_VERSION%\bin\cmake.exe --build . --target install --config Debug 
 %ANDROID_HOME%\cmake\%NDK_CMAKE_VERSION%\bin\cmake.exe --build . --target install --config Release 

echo PRESS ENTER

PAUSE

mkdir %TL_LIBRARIES_PATH%\_build\android\re2 & cd %TL_LIBRARIES_PATH%\_build\android\re2


"%ANDROID_HOME%\cmake\%NDK_CMAKE_VERSION%\bin\cmake.exe" -G "Ninja" ^
 -DCMAKE_SKIP_RPATH=ON ^
 -DCMAKE_USE_RELATIVE_PATHS==ON ^
 -DCMAKE_POSITION_INDEPENDENT_CODE=ON ^
 -DCMAKE_TOOLCHAIN_FILE="%NDKROOT%\build\cmake\android.toolchain.cmake" ^
 -DCMAKE_MAKE_PROGRAM=%ANDROID_HOME%\cmake\%NDK_CMAKE_VERSION%\bin\ninja.exe ^
 -DANDROID_ABI=arm64-v8a -DANDROID_PLATFORM=android-21 ^
 -DCMAKE_INSTALL_PREFIX=%TL_LIBRARIES_PATH%/output/re2 ^
 -DCMAKE_INSTALL_LIBDIR="lib/android/arm64-v8a/$<$<CONFIG:Debug>:Debug>$<$<CONFIG:Release>:Release>" ^
 -DCMAKE_INSTALL_CMAKEDIR=lib/android/arm64-v8a/cmake -DRE2_BUILD_TESTING=OFF ^
 %TL_LIBRARIES_PATH%/Source/re2/re2-20220601 
::%ANDROID_HOME%\cmake\%NDK_CMAKE_VERSION%\bin\cmake.exe --build . --target install --config Debug 
%ANDROID_HOME%\cmake\%NDK_CMAKE_VERSION%\bin\cmake.exe --build . --target install --config Release 


echo PRESS ENTER

PAUSE

mkdir %TL_LIBRARIES_PATH%\_build\android\protobuf & cd %TL_LIBRARIES_PATH%\_build\android\protobuf

"%ANDROID_HOME%\cmake\%NDK_CMAKE_VERSION%\bin\cmake.exe" -G "Ninja" ^
 -DCMAKE_SKIP_RPATH=ON ^
 -DCMAKE_USE_RELATIVE_PATHS==ON ^
 -DCMAKE_POSITION_INDEPENDENT_CODE=ON  ^
 -DCMAKE_TOOLCHAIN_FILE="%NDKROOT%\build\cmake\android.toolchain.cmake" ^
 -DCMAKE_MAKE_PROGRAM=%ANDROID_HOME%\cmake\%NDK_CMAKE_VERSION%\bin\ninja.exe ^
 -DANDROID_ABI=arm64-v8a -DANDROID_PLATFORM=android-21 -Dprotobuf_DEBUG_POSTFIX="" ^
 -DCMAKE_INSTALL_PREFIX=%TL_LIBRARIES_PATH%/output/protobuf ^
 -DCMAKE_INSTALL_LIBDIR="lib/android/arm64-v8a/$<$<CONFIG:Debug>:Debug>$<$<CONFIG:Release>:Release>" ^
 -DCMAKE_INSTALL_CMAKEDIR=lib/android/arm64-v8a/cmake -DCMAKE_CXX_STANDARD=17 ^
 -Dprotobuf_BUILD_TESTS=false -Dprotobuf_WITH_ZLIB=false ^
 -Dprotobuf_BUILD_PROTOC_BINARIES=false -Dprotobuf_BUILD_LIBPROTOC=false ^
 -Dprotobuf_ABSL_PROVIDER=package -Dabsl_DIR="%TL_LIBRARIES_PATH%/output/abseil/lib/android/arm64-v8a/cmake" ^
 %TL_LIBRARIES_PATH%/Source/protobuf/protobuf-4.23.x 
 ::%ANDROID_HOME%\cmake\%NDK_CMAKE_VERSION%\bin\cmake.exe --build . --target install --config Debug 
 %ANDROID_HOME%\cmake\%NDK_CMAKE_VERSION%\bin\cmake.exe --build . --target install --config Release 
 
 echo PRESS ENTER

PAUSE
 
 mkdir %TL_LIBRARIES_PATH%\_build\android\grpc & cd %TL_LIBRARIES_PATH%\_build\android\grpc

"%ANDROID_HOME%\cmake\%NDK_CMAKE_VERSION%\bin\cmake.exe" -G "Ninja" ^
 -DCMAKE_SKIP_RPATH=ON ^
 -DCMAKE_USE_RELATIVE_PATHS==ON ^
 -DCMAKE_POSITION_INDEPENDENT_CODE=ON ^
 -DCMAKE_TOOLCHAIN_FILE="%NDKROOT%\build\cmake\android.toolchain.cmake" ^
 -DCMAKE_MAKE_PROGRAM=%ANDROID_HOME%\cmake\%NDK_CMAKE_VERSION%\bin\ninja.exe ^
 -DANDROID_ABI=arm64-v8a -DANDROID_PLATFORM=android-30 -DCMAKE_CXX_STANDARD=17 ^
 -DCMAKE_INSTALL_PREFIX=%TL_LIBRARIES_PATH%/output/grpc ^
 -DgRPC_INSTALL_LIBDIR="lib/android/arm64-v8a/$<$<CONFIG:Debug>:Debug>$<$<CONFIG:Release>:Release>" ^
 -DgRPC_INSTALL_CMAKEDIR=lib/android/arm64-v8a/cmake ^
 -DgRPC_ABSL_PROVIDER=package -Dabsl_DIR="%TL_LIBRARIES_PATH%/output/abseil/lib/android/arm64-v8a/cmake" ^
 -DgRPC_RE2_PROVIDER=package -Dre2_DIR="%TL_LIBRARIES_PATH%/output/re2/lib/android/arm64-v8a/cmake" ^
 -DgRPC_PROTOBUF_PROVIDER=package ^
 -DProtobuf_DIR="%TL_LIBRARIES_PATH%/output/protobuf/lib/android/arm64-v8a/cmake" ^
 -Dutf8_range_DIR="%TL_LIBRARIES_PATH%/output/protobuf/lib/android/arm64-v8a/cmake" ^
 -DgRPC_USE_CARES=OFF -DgRPC_ZLIB_PROVIDER=package ^
 -DZLIB_INCLUDE_DIR="%UE_THIRD_PARTY_PATH%/zlib/v1.2.8/include" ^
 -DgRPC_SSL_PROVIDER=package ^
 -DOPENSSL_INCLUDE_DIR="%UE_THIRD_PARTY_PATH%/OpenSSL/1.1.1k/include/Android" ^
 -DOPENSSL_SSL_LIBRARY="%UE_THIRD_PARTY_PATH%/OpenSSL/1.1.1k/lib/Android/ARM64/libssl.a" ^
 -DOPENSSL_CRYPTO_LIBRARY="%UE_THIRD_PARTY_PATH%/OpenSSL/1.1.1k/lib/Android/ARM64/libcrypto.a" ^
 -DgRPC_BUILD_CODEGEN=OFF -DgRPC_BUILD_CSHARP_EXT=OFF ^
 %TL_LIBRARIES_PATH%/Source/grpc/grpc-1.57 
::%ANDROID_HOME%\cmake\%NDK_CMAKE_VERSION%\bin\cmake.exe --build . --target install --config Debug 
%ANDROID_HOME%\cmake\%NDK_CMAKE_VERSION%\bin\cmake.exe --build . --target install --config Release
 
ENDLOCAL