package battery.platform.macos;

/**
	macOS, through IOKit.

	The payload is declared once, here, and `kui` renders it into whatever the
	link step of the moment speaks — `@:buildXml` where hxcpp does the linking,
	and a resolved sidecar where it does not.
**/
@:kuiNative({
	// The same two frameworks, said twice — because the two link steps that reach
	// macOS want them said differently. Under `pui` and `cui`, hxcpp does the
	// linking and takes `-framework IOKit` on its own line. Under `sui`, hxcpp
	// only compiles this file into a static library and **Xcode** does the
	// linking, where a framework is a project setting rather than a flag.
	//
	// That is the whole reason a payload is keyed by toolchain rather than by
	// platform: one operating system, two link steps, two things to say.
	hxcpp: {
		files: ["native/battery_mac.mm"],
		libs: ["-framework", "IOKit", "-framework", "CoreFoundation"],
	},
	xcode: {
		frameworks: ["IOKit", "CoreFoundation"],
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
