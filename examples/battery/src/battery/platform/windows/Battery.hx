package battery.platform.windows;

/**
	Windows, through the power-management API.

	The same C++ file serves `pui` and `wui`, and the payload says the same
	library name twice because the two backends link differently on the very same
	operating system:

	- `pui` lets hxcpp compile **and** link, so `hxcpp.libs` is read and that is
	  the end of it;
	- `wui` lets hxcpp compile into `lib<App>.lib` and stop — the `main` WinUI
	  provides would clash with hxcpp's — so **MSBuild** performs the only link
	  there is, and reads nothing hxcpp wrote. Its `AdditionalDependencies` come
	  from `msbuild.libs`.

	The source itself is declared **only** under `hxcpp`. Naming it under
	`msbuild.sources` as well would compile it twice under `wui` — once into the
	static library, once by MSBuild — and the link would fail on duplicate
	symbols. `msbuild.sources` is for code MSBuild alone can build: something that
	needs the WinUI headers, or C++/WinRT.
**/
@:kuiNative({
	hxcpp: {
		files: ["native/battery_win.cpp"],
		libs: ["PowrProf.lib"],
	},
	msbuild: {
		libs: ["PowrProf.lib"],
	},
})
@:cppFileCode('extern "C" int kui_battery_level();
extern "C" bool kui_battery_powered();
extern "C" bool kui_battery_charging();')
class Battery implements battery.Battery {
	public function new() {}

	public function level():Int
		return untyped __cpp__("kui_battery_level()");

	public function powered():Bool
		return untyped __cpp__("kui_battery_powered()");

	public function charging():Bool
		return untyped __cpp__("kui_battery_charging()");
}
