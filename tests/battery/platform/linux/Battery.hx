package battery.platform.linux;

/**
	Deliberately declares **no** native payload.

	It exists to hold `kui` to the harder half of the reserved-name rule: `linux`
	is defined as `1` by gcc outside strict ISO mode, so this package alone
	breaks the generated C++ — with nothing native in it at all. The `-Ulinux`
	has to be emitted for a capability like this one, not only for a capability
	that happens to carry a `.cpp`.
**/
class Battery implements battery.Battery {
	public function new() {}

	public function level():Int return 87;
}
