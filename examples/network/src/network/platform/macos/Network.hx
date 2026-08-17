package network.platform.macos;

/**
	macOS, through SystemConfiguration.

	The framework is named for both link steps, as the battery capability's
	macOS half is: hxcpp links it directly under `pui` and `cui`, and Xcode
	links it as a project setting under `sui`. One operating system, two things
	to say.
**/
@:kuiNative({
	hxcpp: {
		files: ["native/network_mac.mm"],
		libs: ["-framework", "SystemConfiguration"],
	},
	xcode: {
		frameworks: ["SystemConfiguration"],
	},
})
@:cppFileCode('extern "C" bool kui_network_online();')
class Network implements network.Network {
	public function new() {}

	public function online():Bool
		return untyped __cpp__("kui_network_online()");
}
