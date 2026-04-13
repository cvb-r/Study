cmake_minimum_required(VERSION 3.10)
project(qlib)

set(CMAKE_CXX_STANDARD 20)
set(CMAKE_WINDOWS_EXPORT_ALL_SYMBOLS ON)

add_library(qlib SHARED qlib.cpp)

# Принудительно 64-bit (уберите если нужно 32)
if(CMAKE_SIZEOF_VOID_P EQUAL 4)
    message("Building 32-bit")
else()
    message("Building 64-bit")
endif()