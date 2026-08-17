package network.platform.linux;

/**
	Linux, through sysfs.

	Declared for both toolchains that reach this platform — hxcpp under `cui`,
	qmake under `pui`'s Qt surface — because they link differently and neither
	reads what the other was told. The battery capability learned that the hard
	way, at the link step; this one is written knowing it.
**/
@:kuiNative({
	hxcpp: {
		files: ["native/network_linux.cpp"],
	},
	qmake: {
		files: ["native/network_linux.cpp"],
	},
})
@:cppFileCode('extern "C" bool kui_network_online();')
class Network implements network.Network {
	public function new() {}

	public function online():Bool
		return untyped __cpp__("kui_network_online()");
}
