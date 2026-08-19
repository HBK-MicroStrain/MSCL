cmake_minimum_required(VERSION 3.16)
project(MSCL-Cpp-Consumer-Smoke-Test LANGUAGES CXX)

set(CMAKE_CXX_STANDARD 14)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

# This project intentionally consumes an already-installed MSCL package via
# find_package(), the same way an external MSCL user would. It is deliberately
# NOT part of the main MSCL build (MSCL_BUILD_TESTS) - CI configures, builds,
# and runs it as a separate step against the main build's install output, to
# guard against regressions in cmake/mscl-config.cmake.in (the exported
# package config), independently of any wireless/inertial/displacement
# hardware.

if(NOT DEFINED MSCL_ROOT_DIR)
    message(FATAL_ERROR "MSCL_ROOT_DIR must be set to the installed MSCL package location")
endif()

list(APPEND CMAKE_PREFIX_PATH "${MSCL_ROOT_DIR}")

find_package(MSCL REQUIRED CONFIG)

add_executable(smoke-test main.cpp)

target_link_libraries(smoke-test PRIVATE ${MSCL_LIBRARIES})
target_include_directories(smoke-test PRIVATE ${MSCL_INCLUDE_DIRS})
target_precompile_headers(smoke-test PRIVATE "${MSCL_INCLUDE_DIR}/mscl/stdafx.h")
