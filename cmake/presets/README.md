### CMake Presets

This directory contains CMake
[presets](https://cmake.org/cmake/help/latest/manual/cmake-presets.7.html) for
the project. CMake presets provide a way to share common configure, build, test,
package, and workflow settings among developers.

#### Configuration Strategy

Because of the complexity and variety of supported system configurations, we do
not offer every possible combination of configuration options. Instead, we
provide individual presets for each major component (e.g., C++ static libraries,
C++ shared libraries, C# examples, Python bindings, etc.). Each of these options
is available as a standalone preset across the different preset types
(configure, build, etc.).

Aside from these individual configurations, we also provide an "all"
configuration designed to work for most development scenarios by enabling all
standard features and bindings. No other combined configurations
are provided.

#### Listing Available Presets

Use the following commands to list the presets available on your specific
system:

- To list **configure** presets:
  ```shell
  cmake --list-presets=configure
  ```

- To list **build** presets:
  ```shell
  cmake --list-presets=build
  ```

- To list **test** presets:
  ```shell
  cmake --list-presets=test
  ```

- To list **package** presets:
  ```shell
  cmake --list-presets=package
  ```

- To list **workflow** presets:
  ```shell
  cmake --list-presets=workflow
  ```

Note: CMake presets don't support filtering by compiler. You must have the
specified compiler installed and configured on your system to use the selected
preset(s). The presets do, however, support filtering by OS/system.

#### Usage Instructions

Once you have identified the preset you wish to use, you can execute it using the following commands:

- To **configure** using a preset:
  ```shell
  cmake --preset <configure-preset-name>
  ```

- To **build** using a preset:
  ```shell
  cmake --build --preset <build-preset-name>
  ```

- To **test** using a preset:
  ```shell
  ctest --preset <test-preset-name>
  ```

- To **package** using a preset:
  ```shell
  cpack --preset <package-preset-name>
  ```

- To run a **workflow** preset:
  ```shell
  cmake --workflow --preset <workflow-preset-name>
  ```
