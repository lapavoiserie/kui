package network.platform.sailfish;

/**
	SailfishOS, through sysfs — the same C++ as desktop Linux.

	A separate class for a separate platform, sharing the source file: what they
	have in common is that the kernel exposes the same `/sys/class/net` tree, and
	what they do not is everything above it. The day this one needs `connman`,
	only this one changes.

	Declared for `qmake` alone: on Qt, hxcpp only generates C++ and the `.pro`
	compiles and links all of it.
**/
@:kuiNative({
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
