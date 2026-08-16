package battery.platform.ios;

/**
	iOS, through UIKit.

	A separate platform from `macos`, and this is the case that shows why the
	list is keyed by operating system rather than by vendor: the two are both
	Apple, both reached through Xcode, and they cannot share a line of this. The
	IOKit power-source API the macOS half calls is not public on iOS, and
	`UIDevice` does not exist on macOS.

	## Two link steps again, and the same reason

	- `sui` — hxcpp compiles this into `libhaxe.a` and **Xcode** links the app;
	- `pui` — hxcpp compiles, and the application's own `build-ios.sh` links.

	Both are declared. `UIKit` is one an iOS target links anyway, so saying it
	changes nothing today; it is said because the payload is a statement of what
	this code needs, not a list of what happens to be missing.
**/
@:kuiNative({
	hxcpp: {
		files: ["native/battery_ios.mm"],
		libs: ["-framework", "UIKit", "-framework", "Foundation"],
	},
	xcode: {
		frameworks: ["UIKit"],
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
