package battery.platform.macos;

/**
	macOS, through IOKit.

	The payload is declared once, here, and `kui` renders it into whatever the
	link step of the moment speaks — `@:buildXml` where hxcpp does the linking,
	and a resolved sidecar where it does not.
**/
@:kuiNative({
	hxcpp: {
		files: ["native/battery_mac.mm"],
		libs: ["-framework", "IOKit", "-framework", "CoreFoundation"],
	},
})
@:cppFileCode('extern "C" int kui_battery_level();
extern "C" bool kui_battery_charging();')
class Battery implements battery.Battery {
	public function new() {}

	public function level():Int
		return untyped __cpp__("kui_battery_level()");

	public function charging():Bool
		return untyped __cpp__("kui_battery_charging()");
}
