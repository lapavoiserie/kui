package battery;

/**
	What a machine with a battery can answer.

	The declaration, and the whole of what an application sees. It names no
	platform and no backend: `kui.Kui.get(battery.Battery)` resolves whichever
	`battery.platform.<id>.Battery` the build is for.

	Two methods over primitives, which is not modesty. Values crossing a native
	boundary should be `Int`, `Float`, `Bool` or `String` — that constraint is
	`qui`'s, stated since its native modules existed, and it is what survives JNI
	and the CPPIA interpreter alike.
**/
interface Battery extends kui.Capability {
	/** Charge remaining, 0 to 100, or -1 where the machine has no battery. **/
	function level():Int;

	/** Whether it is charging. **/
	function charging():Bool;
}
