package battery.platform.sailfish;

/**
	The qmake half of the test capability.

	The path is `tests/native/...` rather than `native/...` because `@:kuiNative`
	paths are relative to the **library root** — the directory holding
	`haxelib.json` — and this capability lives inside `kui`'s own repository, so
	that root is `kui/`, not `kui/tests/`. A capability shipped as its own haxelib
	would write `native/...`, which is what the example in `examples/battery`
	does.
**/
@:kuiNative({qmake: {files: ["tests/native/battery_stub.cpp"]}})
class Battery implements battery.Battery {
	public function new() {}

	public function level():Int return 87;
}
