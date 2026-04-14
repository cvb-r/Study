cmake_minimum_required(VERSION 3.10)
project(qlib)

set(CMAKE_CXX_STANDARD 20)
set(CMAKE_WINDOWS_EXPORT_ALL_SYMBOLS ON)

add_library(qlib SHARED qlib.cpp)
