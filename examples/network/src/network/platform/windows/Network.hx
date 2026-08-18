package network.platform.windows;

/**
	Windows, through WinINet.

	The library is named twice, and that is the battery capability's hardest
	lesson restated: under `pui` hxcpp links and reads `hxcpp.libs`; under `wui`
	hxcpp only compiles — the `main` WinUI provides would clash with hxcpp's —
	and **MSBuild** performs the only link there is, reading `msbuild.libs`.
	One operating system, two link steps, two places to say `wininet.lib`.
**/
@:kuiNative({
	hxcpp: {
		files: ["native/network_win.cpp"],
		libs: ["wininet.lib"],
	},
	msbuild: {
		libs: ["wininet.lib"],
	},
})
@:cppFileCode('extern "C" bool kui_network_online();')
class Network implements network.Network {
	public function new() {}

	public function online():Bool
		return untyped __cpp__("kui_network_online()");
}
