// A file that exists, which is the whole point of it.
//
// The qmake channel is the one that *copies* what a payload names, so the check
// in `run.sh` needs something on disk to copy. It is never compiled: the tests
// run interpreted, with no toolchain.
extern "C" int kui_test_battery_level() { return 87; }
