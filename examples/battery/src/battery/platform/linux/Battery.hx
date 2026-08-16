package battery.platform.linux;

/**
	Desktop Linux, through sysfs.

	The same C++ file as `battery.platform.sailfish.Battery`, and a separate
	class on purpose. They are separate platforms — Sailjail, Silica and
	Harbour's list of allowed libraries exist on one side only — and sharing the
	source file is how the two say what they have in common without pretending to
	be the same thing. The day one of them needs UPower, only that one changes.

	## Two toolchains, and forgetting one only fails at the link

	Linux is reached two ways, and they could hardly differ more: through `pui`'s
	Qt surface, where hxcpp merely *generates* C++ and qmake compiles and links
	all of it; and through `cui`, where hxcpp does both itself.

	So the same file is declared twice. It was first declared for qmake alone,
	because that is the build that existed — and the Qt build was perfectly happy.
	`cui` then failed at the **link**, with `undefined reference to
	kui_battery_charging`, having compiled everything without complaint: nothing
	had told hxcpp there was a `.cpp` to compile at all.

	That is the whole argument for keying a payload by toolchain rather than by
	platform, stated by the one implementation that got it wrong first.

	Which of the two a Qt build is for cannot be worked out in Haxe:
	`build-pui-linux.hxml` and `build-pui-sailfish.hxml` are identical apart from
	`-D kui_platform`, because only `DEFINES += PUI_SAILFISH` in the `.pro`
	separates them — the C++ preprocessor, long after macros have run. So the
	build file says which, by name.
**/
@:kuiNative({
	// The same source, said twice, because two different build systems reach
	// this platform and neither reads what the other was told.
	hxcpp: {
		files: ["native/battery_sysfs.cpp"],
	},
	qmake: {
		files: ["native/battery_sysfs.cpp"],
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
