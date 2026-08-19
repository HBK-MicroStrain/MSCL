# MSCL Examples

Example projects are provided for some MSCL use cases. This does not encompass
all features of MSCL. Please refer to the
[MSCL documentation](https://hbk-microstrain.github.io/MSCL-Documentation)
for more details.

#### CMake Options

| Option                       | Description                         | Default |
|:-----------------------------|:------------------------------------|:--------|
| `MSCL_BUILD_CPP_EXAMPLES`    | Enables C++ examples.               | `OFF`   |
| `MSCL_BUILD_CSHARP_EXAMPLES` | Enables C# examples. (Windows only) | `OFF`   |

## Examples by Language

- [**C++**](cpp/README.md) - Examples using the C++ MSCL library.
- [**C# / .NET**](csharp/README.md) - Examples using the C# MSCL library.

## Examples by Product Line

Each language directory contains examples for the following product lines:
- **Wireless** - Example code for MicroStrain's Wireless product line.
- **Inertial** - Example code for MicroStrain's Inertial product line.
- **Displacement** - Example code for MicroStrain's Displacement product line.

## Building and Running Examples

The recommended way to build and run the C++ and C# examples is using
**CMake**. Each example is configured to work either as part of the main MSCL
build or as a standalone project.

Python examples run directly against the `pymscl` package from PyPI and do
not use CMake.

For detailed instructions on how to build and run examples for a specific
language, please see the README in the corresponding language directory.
