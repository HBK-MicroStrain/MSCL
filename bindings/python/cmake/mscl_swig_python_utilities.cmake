macro(mscl_add_swig_python_module_library MSCL_PYTHON_VERSION MSCL_PYTHON_MAJOR_VERSION)
    set(MSCL_PYTHON_COMPONENT_NAME "Python${MSCL_PYTHON_VERSION}")
    set(MSCL_PYTHON_TARGET_NAME "${PROJECT_NAME}-${MSCL_PYTHON_COMPONENT_NAME}")

    # Set some linker options
    if(MSVC)
        set(MSCL_PYTHON_LINK_OPTIONS
            "$<$<CONFIG:Release>:/LTCG>"
        )
    else()
        set(MSCL_PYTHON_LINK_OPTIONS
            "-Wl,--no-as-needed"
        )
    endif()

    # Set the output directory similar to how actual libraries/projects output artifacts
    # This allows multiple versions of Python to be build without overwriting the previous artifacts
    set(MSCL_PYTHON_OUTPUT_DIRECTORY "${CMAKE_CURRENT_BINARY_DIR}/${MSCL_PYTHON_TARGET_NAME}")
    if(MSVC)
        string(APPEND MSCL_PYTHON_OUTPUT_DIRECTORY "/$<CONFIG>")
    endif()

    mscl_add_swig_module_library(
        LIB_NAME "${MSCL_PYTHON_TARGET_NAME}"
        MODULE_LANGUAGE "python"
        LINK_OPTIONS ${MSCL_PYTHON_LINK_OPTIONS}
        OUTFILE_DIR "${MSCL_PYTHON_OUTPUT_DIRECTORY}"
    )

    # Make sure all the artifacts are output in their own build directories
    set_target_properties("${MSCL_PYTHON_TARGET_NAME}" PROPERTIES
        ARCHIVE_OUTPUT_DIRECTORY "${MSCL_PYTHON_OUTPUT_DIRECTORY}"
        RUNTIME_OUTPUT_DIRECTORY "${MSCL_PYTHON_OUTPUT_DIRECTORY}"
        LIBRARY_OUTPUT_DIRECTORY "${MSCL_PYTHON_OUTPUT_DIRECTORY}"
    )

    # Add the target to a list to build all targets
    list(APPEND MSCL_PYTHON${MSCL_PYTHON_MAJOR_VERSION}_ALL_TARGETS "${MSCL_PYTHON_TARGET_NAME}")

    set(PYTHON_PACKAGE_NAME "Python${MSCL_PYTHON_MAJOR_VERSION}")
    set(${PYTHON_PACKAGE_NAME}_USE_STATIC_LIBS ${MSCL_LINK_STATIC_DEPS})

    # Find the required Python package
    find_package("${PYTHON_PACKAGE_NAME}"
        "${MSCL_PYTHON_VERSION}" EXACT
        REQUIRED
        COMPONENTS "Development"
    )

    # Link/include the required Python package
    target_link_libraries("${MSCL_PYTHON_TARGET_NAME}" PRIVATE
        ${${PYTHON_PACKAGE_NAME}_LIBRARIES}
    )
    target_include_directories("${MSCL_PYTHON_TARGET_NAME}" PRIVATE
        "${${PYTHON_PACKAGE_NAME}_INCLUDE_DIRS}"
    )

    # vcpkg doesn't provide pdb files for debug builds of Python
    if(MSVC)
        target_link_options("${MSCL_PYTHON_TARGET_NAME}" PRIVATE
            "/ignore:4099"
        )
    endif()

    # Python 3.10 doesn't seem to link ZLIB properly through vcpkg
    # Make sure it's actually linked
    if(WIN32 AND MSCL_PYTHON_VERSION MATCHES "^3\.10")
        find_package("ZLIB" REQUIRED)
        target_link_libraries("${MSCL_PYTHON_TARGET_NAME}" PRIVATE
            ${ZLIB_LIBRARIES}
        )
    endif()

    # Get the generated .py files
    get_target_property(MSCL_GENERATED_PYTHON_SOURCES "${MSCL_PYTHON_TARGET_NAME}" SWIG_SUPPORT_FILES)

    # Installation
    if(MSVC)
        string(REPLACE "\." "" MSCL_PYTHON_INSTALL_DIR_VERSION "${MSCL_PYTHON_VERSION}")
        set(MSCL_PYTHON_SITE_PACKAGES_DIR "Python${MSCL_PYTHON_INSTALL_DIR_VERSION}/Lib/site-packages")
    else()
        set(MSCL_PYTHON_SITE_PACKAGES_DIR ${CMAKE_INSTALL_LIBDIR}/python${MSCL_PYTHON_VERSION}/)

        microstrain_detect_deb(MSCL_IS_DEB)
        if(MSCL_IS_DEB)
            string(APPEND MSCL_PYTHON_SITE_PACKAGES_DIR "dist-packages")
        else()
            string(APPEND MSCL_PYTHON_SITE_PACKAGES_DIR "site-packages")
        endif()
    endif()

    set(MSCL_PYTHON_INSTALL_CONFIGURATIONS "Release")
    if(MSCL_PACKAGE_PYTHON_DEBUG)
        list(APPEND MSCL_PYTHON_INSTALL_CONFIGURATIONS "Debug")
    endif()

    install(
        TARGETS "${MSCL_PYTHON_TARGET_NAME}"
        CONFIGURATIONS ${MSCL_PYTHON_INSTALL_CONFIGURATIONS}
        RUNTIME
            COMPONENT "${MSCL_PYTHON_COMPONENT_NAME}"
            DESTINATION "${MSCL_PYTHON_SITE_PACKAGES_DIR}"
        LIBRARY
            COMPONENT "${MSCL_PYTHON_COMPONENT_NAME}"
            DESTINATION "${MSCL_PYTHON_SITE_PACKAGES_DIR}"
    )

    install(
        FILES "${MSCL_GENERATED_PYTHON_SOURCES}"
        DESTINATION "${MSCL_PYTHON_SITE_PACKAGES_DIR}"
        CONFIGURATIONS ${MSCL_PYTHON_INSTALL_CONFIGURATIONS}
        COMPONENT "${MSCL_PYTHON_COMPONENT_NAME}"
    )

    if(MSCL_BUILD_PACKAGE)
        microstrain_set_cpack_component_file_name(
            COMPONENT_NAME "${MSCL_PYTHON_COMPONENT_NAME}"
            COMPONENT_VERSION "${CPACK_PACKAGE_VERSION}"
            PACKAGE_ARCH "${CPACK_SYSTEM_NAME}"
        )
    endif()
endmacro()

# Builds a single Python3 binding library against the stable ABI (Py_LIMITED_API).
# The resulting binary works with any Python 3.x >= MSCL_PYTHON_ABI_VERSION without rebuilding,
# instead of needing one build per exact Python minor version.
macro(mscl_add_swig_python_abi3_module_library MSCL_PYTHON_ABI_VERSION)
    # The target name must match MSCL_PYTHON_ABI_VERSION (e.g. "Python3.11") since that's what the
    # generated examples projects (examples/python/cmake/CMakeLists.txt.in) expect to depend on --
    # it hardcodes "@PROJECT_NAME@-Python@MSCL_PYTHON_VERSION@" using MSCL_PYTHON_REQUESTED_VERSIONS.
    set(MSCL_PYTHON_TARGET_NAME "${PROJECT_NAME}-Python${MSCL_PYTHON_ABI_VERSION}")

    # Unlike the target name, the install/CPack component name has no such constraint -- this macro
    # only ever configures a single Python component per build, so keep it version-independent
    # (rather than tied to MSCL_PYTHON_ABI_VERSION) so consumers like pyproject.toml's
    # `install.components` don't need updating every time the ABI baseline version changes.
    set(MSCL_PYTHON_COMPONENT_NAME "Python3")

    if(MSVC)
        set(MSCL_PYTHON_LINK_OPTIONS
            "$<$<CONFIG:Release>:/LTCG>"
        )
    else()
        set(MSCL_PYTHON_LINK_OPTIONS
            "-Wl,--no-as-needed"
        )
    endif()

    set(MSCL_PYTHON_OUTPUT_DIRECTORY "${CMAKE_CURRENT_BINARY_DIR}/${MSCL_PYTHON_TARGET_NAME}")
    if(MSVC)
        string(APPEND MSCL_PYTHON_OUTPUT_DIRECTORY "/$<CONFIG>")
    endif()

    mscl_add_swig_module_library(
        LIB_NAME "${MSCL_PYTHON_TARGET_NAME}"
        MODULE_LANGUAGE "python"
        LINK_OPTIONS ${MSCL_PYTHON_LINK_OPTIONS}
        OUTFILE_DIR "${MSCL_PYTHON_OUTPUT_DIRECTORY}"
    )

    set_target_properties("${MSCL_PYTHON_TARGET_NAME}" PROPERTIES
        ARCHIVE_OUTPUT_DIRECTORY "${MSCL_PYTHON_OUTPUT_DIRECTORY}"
        RUNTIME_OUTPUT_DIRECTORY "${MSCL_PYTHON_OUTPUT_DIRECTORY}"
        LIBRARY_OUTPUT_DIRECTORY "${MSCL_PYTHON_OUTPUT_DIRECTORY}"
    )

    # CMake's Development.Module/Development.SABIModule sub-components need to execute the found
    # interpreter to introspect sysconfig, which fails against this vcpkg-built Python (it isn't
    # runnable standalone outside its own package tree). The plain Development component is what
    # vcpkg's python3 port itself documents and is proven to work, so use that for the include
    # directories and handle version-independent linking ourselves below instead of relying on
    # CMake's (broken, for this build) automatic Module/SABIModule detection.
    set(Python3_USE_STATIC_LIBS ${MSCL_LINK_STATIC_DEPS})
    find_package(Python3
        "${MSCL_PYTHON_ABI_VERSION}"
        REQUIRED
        COMPONENTS Development
    )

    target_include_directories("${MSCL_PYTHON_TARGET_NAME}" PRIVATE
        ${Python3_INCLUDE_DIRS}
    )

    if(WIN32)
        # Extension modules must resolve every symbol at link time on Windows, unlike Unix shared
        # objects. Link the version-independent "python3.lib" stable-ABI stub (shipped alongside
        # the version-specific pythonXY.lib in CPython's Windows distribution) instead of
        # Python3_LIBRARIES (which would be the version-specific pythonXY.lib), so the built .pyd
        # isn't tied to one exact Python version.
        find_library(MSCL_PYTHON_ABI_LIBRARY
            NAMES "python3"
            PATHS ${Python3_LIBRARY_DIRS}
            NO_DEFAULT_PATH
            REQUIRED
        )
        target_link_libraries("${MSCL_PYTHON_TARGET_NAME}" PRIVATE "${MSCL_PYTHON_ABI_LIBRARY}")
    endif()
    # On Linux/Unix, deliberately don't link against libpythonX.Y.so at all: its Python C-API
    # symbols stay undefined in the built .so and are resolved at import time from the hosting
    # interpreter process. That's the standard way to build a Python-version-independent
    # extension on Unix -- linking libpythonX.Y.so directly would tie the .so to that one version.

    # Restrict the compiled module to the stable ABI surface so it stays
    # forward-compatible with newer Python 3.x releases without rebuilding
    string(REPLACE "." ";" MSCL_PYTHON_ABI_VERSION_LIST "${MSCL_PYTHON_ABI_VERSION}")
    list(GET MSCL_PYTHON_ABI_VERSION_LIST 0 MSCL_PYTHON_ABI_MAJOR)
    list(GET MSCL_PYTHON_ABI_VERSION_LIST 1 MSCL_PYTHON_ABI_MINOR)
    math(EXPR MSCL_PYTHON_LIMITED_API_HEX "(${MSCL_PYTHON_ABI_MAJOR} << 24) | (${MSCL_PYTHON_ABI_MINOR} << 16)" OUTPUT_FORMAT HEXADECIMAL)
    target_compile_definitions("${MSCL_PYTHON_TARGET_NAME}" PRIVATE
        "Py_LIMITED_API=${MSCL_PYTHON_LIMITED_API_HEX}"
    )

    # Tag the shared object with the "abi3" infix Python tooling expects for stable-ABI extensions.
    # We set this unconditionally on non-Windows (rather than relying on CMake's Python3_SOSABI,
    # which is only populated by the SABIModule component we're not using on Unix) since we're
    # already manually enforcing the stable ABI restriction via Py_LIMITED_API above.
    if(NOT MSVC)
        set_target_properties("${MSCL_PYTHON_TARGET_NAME}" PROPERTIES
            SUFFIX ".abi3${CMAKE_SHARED_MODULE_SUFFIX}"
        )
    endif()

    if(MSVC)
        target_link_options("${MSCL_PYTHON_TARGET_NAME}" PRIVATE
            "/ignore:4099"
        )
    endif()

    # Get the generated .py files
    get_target_property(MSCL_GENERATED_PYTHON_SOURCES "${MSCL_PYTHON_TARGET_NAME}" SWIG_SUPPORT_FILES)

    # Install to the root of the package so `import mscl` works the same way whether
    # installed via CPack or assembled into a wheel by scikit-build-core
    install(
        TARGETS "${MSCL_PYTHON_TARGET_NAME}"
        CONFIGURATIONS "Release"
        RUNTIME
            COMPONENT "${MSCL_PYTHON_COMPONENT_NAME}"
            DESTINATION "."
        LIBRARY
            COMPONENT "${MSCL_PYTHON_COMPONENT_NAME}"
            DESTINATION "."
    )

    install(
        FILES "${MSCL_GENERATED_PYTHON_SOURCES}"
        DESTINATION "."
        CONFIGURATIONS "Release"
        COMPONENT "${MSCL_PYTHON_COMPONENT_NAME}"
    )

    if(MSCL_BUILD_PACKAGE)
        microstrain_set_cpack_component_file_name(
            COMPONENT_NAME "${MSCL_PYTHON_COMPONENT_NAME}"
            COMPONENT_VERSION "${CPACK_PACKAGE_VERSION}"
            PACKAGE_ARCH "${CPACK_SYSTEM_NAME}"
        )
    endif()
endmacro()

# Get the baseline version for the vcpkg manifest file
execute_process(
    COMMAND ${GIT_EXECUTABLE} rev-parse HEAD
    WORKING_DIRECTORY ${MSCL_VCPKG_DIR}
    OUTPUT_VARIABLE MSCL_VCPKG_BASELINE_VERSION
)
string(STRIP "${MSCL_VCPKG_BASELINE_VERSION}" MSCL_VCPKG_BASELINE_VERSION)

# Use vcpkg to download Python libraries for linking
function(mscl_download_python MSCL_PYTHON_VERSION MSCL_PYTHON_MAJOR_VERSION)
    set(MSCL_PYTHON_PROJECT_DIR "python${MSCL_PYTHON_VERSION}")

    # Build the Python project in the common dependencies directory
    # This allows usage across all configuration types instead of downloading/installing it for each configuration
    set(MSCL_PYTHON_BUILD_DIR "${MSCL_DEPS_BASE_DIR}/${MSCL_PYTHON_PROJECT_DIR}")

    message(STATUS "Installing Python ${MSCL_PYTHON_VERSION}...")
    string(REPLACE "." "" MSCL_PYTHON_VERSION_COMBINED "${MSCL_PYTHON_VERSION}")

    if(MSVC)
        # Append the architecture when building multiple architectures on the same system
        string(APPEND MSCL_PYTHON_BUILD_DIR "/${CMAKE_GENERATOR_PLATFORM}")
    endif()

    # Get the name of the directory where vcpkg installs packages
    # This has and could change in different versions of vcpkg
    get_filename_component(VCPKG_INSALL_DIR_NAME ${VCPKG_INSTALLED_DIR} NAME)
    set(VCPKG_INSTALLED_DIR ${MSCL_PYTHON_BUILD_DIR}/${VCPKG_INSALL_DIR_NAME})

    # Generate the CMake project file
    set(MSCL_PYTHON_CMAKE_FILENAME "CMakeLists.txt")
    configure_file(
        "${CMAKE_CURRENT_LIST_DIR}/${MSCL_PYTHON_CMAKE_FILENAME}.in"
        "${CMAKE_CURRENT_LIST_DIR}/${MSCL_PYTHON_PROJECT_DIR}/${MSCL_PYTHON_CMAKE_FILENAME}"
        @ONLY
    )

    file(READ "${MSCL_VCPKG_DIR}/versions/p-/python${MSCL_PYTHON_MAJOR_VERSION}.json" VCPKG_PYTHON_VERSIONS_CONTENT)

    # Get the number of available version entries
    string(JSON MSCL_PYTHON_VERSION_COUNT LENGTH "${VCPKG_PYTHON_VERSIONS_CONTENT}" "versions")

    foreach(INDEX RANGE 0 ${MSCL_PYTHON_VERSION_COUNT})
        # Get the version number at the given index
        string(JSON MSCL_PYTHON_LATEST_VERSION GET "${VCPKG_PYTHON_VERSIONS_CONTENT}" "versions" ${INDEX} "version")

        # The first match of the requested version should be the latest supported version
        if(MSCL_PYTHON_LATEST_VERSION MATCHES "^${MSCL_PYTHON_VERSION}")
            # Also get the port version for proper installation
            string(JSON MSCL_PYTHON_LATEST_PORT GET "${VCPKG_PYTHON_VERSIONS_CONTENT}" "versions" ${INDEX} "port-version")
            break()
        endif()
    endforeach()

    if(NOT MSCL_PYTHON_LATEST_PORT AND NOT MSCL_PYTHON_LATEST_PORT STREQUAL "0")
        message(FATAL_ERROR "Could not find a supported version for Python ${MSCL_PYTHON_VERSION} in the vcpkg versions file")
    endif()

    # Generate the vcpkg manifest file
    set(MSCL_PYTHON_VCPKG_FILENAME "vcpkg.json")
    configure_file(
        "${CMAKE_CURRENT_LIST_DIR}/${MSCL_PYTHON_VCPKG_FILENAME}.in"
        "${CMAKE_CURRENT_LIST_DIR}/${MSCL_PYTHON_PROJECT_DIR}/${MSCL_PYTHON_VCPKG_FILENAME}"
    )

    # Only set the generator platform option for VS
    if(MSVC)
        set(PYTHON_GENERATOR_PLATFORM "-A ${CMAKE_GENERATOR_PLATFORM}")
    endif()

    # Generate the Python installation project
    execute_process(
        # Generate the Python project using the same CMake configuration
        COMMAND "${CMAKE_COMMAND}"
            -G "${CMAKE_GENERATOR}"
            "${PYTHON_GENERATOR_PLATFORM}"
            -S "${CMAKE_CURRENT_LIST_DIR}/${MSCL_PYTHON_PROJECT_DIR}"
            -B "${MSCL_PYTHON_BUILD_DIR}"
        ECHO_ERROR_VARIABLE
        ECHO_OUTPUT_VARIABLE
        RESULT_VARIABLE _RESULT
        OUTPUT_STRIP_TRAILING_WHITESPACE
        ERROR_STRIP_TRAILING_WHITESPACE

    )

    if(NOT _RESULT EQUAL 0)
        message(FATAL_ERROR "Failed to install Python ${MSCL_PYTHON_VERSION} (exit code: ${_RESULT})")
    endif()

    set(PYTHON_VCPKG_INSTALL_DIR "${MSCL_PYTHON_BUILD_DIR}/vcpkg_installed/${VCPKG_TARGET_TRIPLET}")
    list(PREPEND CMAKE_PREFIX_PATH
        "${PYTHON_VCPKG_INSTALL_DIR}/debug"
        "${PYTHON_VCPKG_INSTALL_DIR}"
    )

    # This is used by the examples to find the interpreter
    set(Python${MSCL_PYTHON_VERSION}_ROOT_DIR "${PYTHON_VCPKG_INSTALL_DIR}/tools/python${MSCL_PYTHON_MAJOR_VERSION}" CACHE INTERNAL "The root directory of the vcpkg installed Python${MSCL_PYTHON_VERSION} interpreter")

    # Allow the calling scope to find python properly
    set(CMAKE_PREFIX_PATH ${CMAKE_PREFIX_PATH} PARENT_SCOPE)
endfunction()
