#include <mscl/stdafx.h>

#include <mscl/MicroStrain/Wireless/BaseStation.h>

#include <cstdio>

// This is a smoke test for consuming MSCL via find_package(MSCL CONFIG) as an
// external project would (see cmake/mscl-config.cmake.in). It does not need
// any real hardware: opening a nonexistent serial port still exercises the
// full pipeline (headers found, library linked, dependencies loaded at
// runtime) and is expected to fail with a clean MSCL exception rather than a
// missing-symbol or DLL-load error.
int main()
{
    try
    {
        mscl::Connection::Serial("NONEXISTENT_PORT_FOR_CI_SMOKE_TEST", 3000000);

        fprintf(stderr, "FAIL: expected an exception opening a nonexistent port, but none was thrown\n");
        return 1;
    }
    catch (const mscl::Error&)
    {
        printf("OK: caught the expected mscl::Error opening a nonexistent serial port\n");
        return 0;
    }
}
