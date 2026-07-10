# MSCL - The MicroStrain Communication Library

MSCL is developed by
[MicroStrain](https://www.hbkworld.com/en/Campaign/microstrain-by-hbk) in
Williston, VT. Its purpose is to serve as a simple user-friendly API to interact
with our [Wireless](https://www.hbkworld.com/en/products/instruments/wireless-daq-systems),
and [Inertial](https://www.hbkworld.com/en/products/transducers/inertial-sensors)
sensors.

[![CI C++ (Windows)](https://github.com/HBK-MicroStrain/MSCL/actions/workflows/ci-cpp-windows.yml/badge.svg)](https://github.com/HBK-MicroStrain/MSCL/actions/workflows/ci-cpp-windows.yml) &nbsp;
[![CI C++ (Linux)](https://github.com/HBK-MicroStrain/MSCL/actions/workflows/ci-cpp-linux.yml/badge.svg)](https://github.com/HBK-MicroStrain/MSCL/actions/workflows/ci-cpp-linux.yml) &nbsp;
[![PyPI](https://img.shields.io/pypi/v/mscl)](https://pypi.org/project/mscl/) &nbsp;
[![NuGet](https://img.shields.io/nuget/v/MicroStrain.MSCL)](https://www.nuget.org/packages/MicroStrain.MSCL/)

### Support

If you have any questions or run into any issues, please let us know!
[MicroStrain Support Portal](https://support.microstrain.com)

Also, have a look at our [FAQs](guides/FAQ.md) for common issues.

### Inertial Successor API

For projects using our latest inertial product lines, check out our new
lightweight C/C++ API, [MIP SDK](https://github.com/LORD-MicroStrain/mip_sdk)

## Releases

Please see our [releases](../../releases) page for all of our release notes.

## Packages

| Language | Package                                                                | Install                                        |
|----------|-------------------------------------------------------------------------|-------------------------------------------------|
| C++      | —                                                                        | See the [Integration guide](guides/Integration.md) below |
| Python   | [mscl](https://pypi.org/project/mscl/)                                  | `pip install mscl`                               |
| C#       | [MicroStrain.MSCL](https://www.nuget.org/packages/MicroStrain.MSCL/)    | `dotnet add package MicroStrain.MSCL`            |

MSCL no longer publishes prebuilt C++ archives with each release. C++ projects
should consume a specific released version directly from source using CMake's
`FetchContent` against a git tag &mdash; see the
[Integration guide](guides/Integration.md) for details.

## Project Integration

See the [Integration guide](guides/Integration.md) for how to consume MSCL
from C++ (via CMake `FetchContent`), Python (via PyPI), and C# (via NuGet).

## Building From Source

If you'd rather build MSCL from source yourself, you can do so with the build
[instructions](guides/Build.md)

## Documentation

MSCL has [online documentation](https://hbk-microstrain.github.io/MSCL_documentation).</br>
See the documentation build [instructions](docs/README.md) for information on
building the documentation from source.

## Examples

MSCL has an array of [examples](examples/README.md) for all supported languages

* Note: LabVIEW example code is provided in the
[LabVIEW-MSCL VI package](https://github.com/LORD-MicroStrain/LabVIEW-MSCL).

## Tests

MSCL has a suite of unit tests to ensure the library functions as expected.</br>
See the testing [instructions](tests/README.md) for more information on building
and running tests.

## License

MSCL is released under the MIT [license](LICENSE)

## Third-Party Notices

MSCL uses additional libraries as part of the project and has separate licensing

- [OpenSSL](License_OpenSSL.txt)
- [Boost](License_Boost.txt)
