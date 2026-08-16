package battery.platform.macos;

@:build(Add.build())
class Battery implements battery.Battery {
	public function new() {}
	public function level():Int return 87;
}
