package network;

/**
	Turning a value you can read into a change you can hear.

	```haxe
	var stop = Watch.changes(net, 1000, isOnline -> online.value = isOnline);
	…
	stop();
	```

	Polling, and stated as such. A capability may not push (see `Network`), so
	somebody has to ask — and doing it here means it is written once, in Haxe,
	for every platform, instead of once per platform in C against a different
	system API each time.

	**It reports changes, not readings.** The callback fires when the answer is
	different from the last one, so a caller cannot accidentally do work every
	tick; the first call fires only if the value differs from `from`.

	**It returns the way to stop.** That return value is the whole reason this
	example exists: an application that starts one of these has taken ownership
	of a timer, and a timer nobody stops is a leak with a heartbeat.
**/
class Watch {
	/**
		Watch `network` and call `changed` when the answer changes.

		Returns a function that stops it. Safe to call more than once.
	**/
	public static function changes(network:Network, everyMs:Int, changed:Bool->Void,
			?from:Null<Bool>):Void->Void {
		var last = from == null ? network.online() : from;
		var timer = new haxe.Timer(everyMs);
		var stopped = false;

		timer.run = () -> {
			var now = network.online();
			if (now == last) return;
			last = now;
			changed(now);
		};

		return () -> {
			if (stopped) return;
			stopped = true;
			timer.stop();
		};
	}
}
