# This is a smoke test for consuming the built/installed mscl Python module, mirroring
# tests/cpp-consumer-smoke/main.cpp. It does not need any real hardware: opening a
# nonexistent serial port still exercises the full pipeline (module found, native
# extension loaded, dependencies resolved at runtime) and is expected to fail with a
# clean RuntimeError rather than an ImportError or a missing-symbol/DLL-load error.
#
# The Python bindings map every C++ mscl::Error (and other std::exception subclasses)
# to a plain RuntimeError -- see the catch-all %exception block in bindings/MSCL_Exceptions.i,
# which applies to all SWIG target languages, not just C#.

import mscl

try:
    mscl.Connection.Serial("NONEXISTENT_PORT_FOR_CI_SMOKE_TEST", 3000000)
except RuntimeError as ex:
    print(f"OK: caught the expected RuntimeError opening a nonexistent serial port: {ex}")
else:
    raise SystemExit("FAIL: expected a RuntimeError opening a nonexistent port, but none was raised")
