package battery.platform.macos;

@:kuiNative({hxcpp: {files: ["native/battery_mac.mm"], libs: ["-framework", "IOKit"]}})
class Battery implements battery.Battery {
	public function new() {}
	public function level():Int return 87;
}
