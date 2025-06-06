cmake_minimum_required(VERSION 3.11)

project(crashpad LANGUAGES C CXX)

set(CMAKE_MODULE_PATH ${CMAKE_MODULE_PATH} "${CMAKE_CURRENT_SOURCE_DIR}/cmake/")

if(MSVC)
    enable_language(ASM_MASM)
else()
    enable_language(ASM)
endif()

set(CMAKE_RUNTIME_OUTPUT_DIRECTORY ${CMAKE_BINARY_DIR})
set(CMAKE_LIBRARY_OUTPUT_DIRECTORY ${CMAKE_BINARY_DIR})

# Option to build unit tests.
option(CRASHPAD_BUILD_TESTS "Build unit tests." OFF)
option(CRASHPAD_INSTALL "Enables the installation target." ON)
option(CRASHPAD_HANDLER_NAME "reset crashpad handler binary name." "")

option(RESET_CMAKE_INSTALL_PREFIX "Reset install path" ON)

if (RESET_CMAKE_INSTALL_PREFIX)
  if (ANDROID)
    set(CMAKE_INSTALL_PREFIX install/${ANDROID_ABI})
  else()
    set(CMAKE_INSTALL_PREFIX install)
  endif()
endif()

# We are going to use the FetchContent module to grab crashpad and its dependencies.
include(FetchContent)

# Try to find prebuilt zlib on the system to link against first before building it ourselves.
# always use static zlib from source code
# find_package(ZLIB 1.2.8)

# If not found, we fetch it and build it ourselves.
if(NOT ZLIB_FOUND AND NOT TARGET ZLIB::ZLIB)
    FetchContent_Declare(
      zlib
      GIT_REPOSITORY https://github.com/madler/zlib.git
      GIT_TAG        v1.2.11
    )
    
    # We don't use FetchContent_MakeAvailable here because we don't want all zlib targets including, just our dependency.
    FetchContent_GetProperties(zlib)
    if(NOT zlib_POPULATED)
      FetchContent_Populate(zlib)
      add_subdirectory(${zlib_SOURCE_DIR} ${zlib_BINARY_DIR} EXCLUDE_FROM_ALL)
    endif()

    # Make sure headers are available for the static target and make an alias to match the Find module output.
#     target_include_directories(zlibstatic INTERFACE ${zlib_SOURCE_DIR} ${zlib_BINARY_DIR})
    add_library(ZLIB::ZLIB ALIAS zlibstatic)

    install(TARGETS zlibstatic
        EXPORT ${PROJECT_NAME}Targets
        RUNTIME DESTINATION bin
        LIBRARY DESTINATION lib
        ARCHIVE DESTINATION lib)
endif()

find_package(Threads)

add_library(AppleFrameworks INTERFACE)

if(APPLE)
    set(FRAMEWORKS CoreFoundation;ApplicationServices;Foundation;IOKit;Security;bsm;OpenCL)
    foreach(FW ${FRAMEWORKS})
        find_library(FW_PATH_${FW} ${FW})
        target_link_libraries(AppleFrameworks INTERFACE ${FW_PATH_${FW}})
    endforeach()
endif()

# Mini-Chromium
FetchContent_Declare(
    mini_chromium_git
    GIT_REPOSITORY https://github.com/chromium/mini_chromium.git
    GIT_TAG        9cdc2a7
)

if(NOT mini_chromium_git_POPULATED)
    FetchContent_Populate(mini_chromium_git)
endif()

# Crashpad
FetchContent_Declare(
    crashpad_git
    GIT_REPOSITORY https://github.com/backtrace-labs/crashpad.git
    GIT_TAG        7b9686b
)

if(NOT crashpad_git_POPULATED)
    FetchContent_Populate(crashpad_git)
endif()

# LSS dependency for linux syscalls.
FetchContent_Declare(
    lss_git
    GIT_REPOSITORY https://chromium.googlesource.com/linux-syscall-support
    GIT_TAG        e1e7b0a
)

if(NOT lss_git_POPULATED)
    FetchContent_Populate(lss_git)
endif()

file(COPY ${lss_git_SOURCE_DIR}/linux_syscall_support.h DESTINATION ${crashpad_git_SOURCE_DIR}/third_party/lss)

include(crashpad-common)
include(minichromium)
include(crashpad-compat)
include(crashpad-tools)
include(crashpad-util)
include(crashpad-client)
include(crashpad-minidump)
include(crashpad-snapshot)
include(crashpad-handler)

# If we want unit tests, build them.
if(CRASHPAD_BUILD_TESTS)
    # Disable tests supplied by zlib source incase we have to build it.
    configure_file(${CMAKE_CURRENT_SOURCE_DIR}/cmake/CTestCustom.cmake ${CMAKE_BINARY_DIR})

    enable_testing()

    # Fetch googletest code.
    include(GoogleTest)
    FetchContent_Declare(
        googletest
        GIT_REPOSITORY https://github.com/google/googletest.git
        GIT_TAG        release-1.10.0
    )

    # We don't use FetchContent_MakeAvailable here because we don't want all googletest targets including, just our dependencies.
    FetchContent_GetProperties(googletest)
    if(NOT googletest_POPULATED)
        FetchContent_Populate(googletest)
    endif()
    include(gtest)
    include(crashpad-test)
    include(crashpad-test-test)
    include(crashpad-util-test)
    include(crashpad-snapshot-test)
    include(crashpad-minidump-test)
    include(crashpad-client-test)
    include(crashpad-handler-test)
endif()

if(CRASHPAD_INSTALL)
    # Add the version in a CMake readable way
#     configure_file("cmake/crashpadConfig.cmake.in" "crashpadConfig.cmake" @ONLY)

#     # Make version available in the install
#     install(FILES "${PROJECT_BINARY_DIR}/crashpadConfig.cmake"
#           DESTINATION "${CMAKE_INSTALL_PREFIX}/cmake/crashpad")

    # Install the export target as a file
    install(
        EXPORT ${PROJECT_NAME}Targets
        FILE crashpadConfig.cmake
        NAMESPACE crashpad::
        DESTINATION "${CMAKE_INSTALL_PREFIX}/cmake/crashpad")

    # Use find_package on the installed package
#     export(
#         TARGETS ${PROJECT_NAME}
#         NAMESPACE crashpad::
#         FILE crashpadTargets.cmake)

#     include(CPack)
endif()
