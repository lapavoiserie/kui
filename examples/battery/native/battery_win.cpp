// Windows, through the power-management API.
//
// `CallNtPowerInformation` is chosen over the simpler `GetSystemPowerStatus`
// for a reason that is the point of this file: it lives in **PowrProf.lib**,
// which MSVC does not link by default. `GetSystemPowerStatus` is in kernel32
// and would have linked with no help from anyone, proving nothing.
//
// So this file needs a library named, and where that name has to be said
// depends on who is linking:
//
//   * under `pui`, hxcpp compiles *and* links, and its own `<lib>` entry is
//     enough — the `hxcpp` section of the payload carries it;
//   * under `wui`, hxcpp compiles this into `lib<App>.lib` and stops, because
//     the `main` WinUI provides would clash with hxcpp's. **MSBuild performs
//     the only link there is**, and it never reads what hxcpp wrote.
//
// One operating system, one source file, two link steps that have to be told
// separately. That is what `kui.build.Payload` being keyed by toolchain is for.

#include <windows.h>
#include <powrprof.h>

extern "C" int kui_battery_level() {
	SYSTEM_BATTERY_STATE state = {};
	if (CallNtPowerInformation(SystemBatteryState, nullptr, 0, &state, sizeof(state)) != 0)
		return -1;
	if (!state.BatteryPresent || state.MaxCapacity == 0)
		return -1;
	return (int)((state.RemainingCapacity * 100ULL) / state.MaxCapacity);
}

extern "C" bool kui_battery_charging() {
	SYSTEM_BATTERY_STATE state = {};
	if (CallNtPowerInformation(SystemBatteryState, nullptr, 0, &state, sizeof(state)) != 0)
		return false;
	return state.Charging != FALSE;
}
