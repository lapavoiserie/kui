package battery;

/**
	What a machine with a battery can answer.

	The declaration, and the whole of what an application sees. It names no
	platform and no backend: `kui.Kui.get(battery.Battery)` resolves whichever
	`battery.platform.<id>.Battery` the build is for.

	Primitives only, which is not modesty. Values crossing a native boundary
	should be `Int`, `Float`, `Bool` or `String` — that constraint is `qui`'s,
	stated since its native modules existed, and it is what survives JNI and the
	CPPIA interpreter alike.

	## Why "charging" is not enough

	This declaration first asked one yes-or-no question, and it was the wrong
	one. A laptop plugged in at 100 % is **not charging** — it is *charged* —
	and an application with only `charging()` to go on will tell its user it is
	running on battery while the charger sits in the wall.

	They are two independent facts, so there are two methods. `powered()` is the
	one an application usually wants; `charging()` only says whether the battery
	is currently filling.

	| `powered()` | `charging()` | The machine is |
	|---|---|---|
	| `true` | `true` | plugged in and filling |
	| `true` | `false` | plugged in and full, or holding at a limit |
	| `false` | `false` | running off the battery |
	| `false` | `true` | impossible; no platform reports it |

	Every implementation must answer both consistently, and the last row is why
	the pair is worth stating rather than leaving each platform to improvise.
**/
interface Battery extends kui.Capability {
	/** Charge remaining, 0 to 100, or -1 where the machine has no battery. **/
	function level():Int;

	/**
		Whether the machine is drawing from external power.

		`true` on a desktop with no battery at all, which is the honest answer:
		it is mains-powered. `level()` still returns -1 there.
	**/
	function powered():Bool;

	/**
		Whether the battery is currently filling.

		**Not** the same as being plugged in: a full battery, or one held at a
		charge limit, reports `false` with the charger connected. Ask `powered()`
		for that.
	**/
	function charging():Bool;
}
