import mui.App;
import mui.View;
import mui.ui.Text;
import mui.ui.VStack;
import rui.Signal;

/**
	Listening for something that changes outside the application.

	This is the case `Effect.onCleanup` exists for, and the one a capability
	that only answers questions — like `battery` — never reaches: the value
	changes **while the application runs**, so something has to keep asking, and
	that something has to be stopped.

	## The shape

	```haxe
	online = new Signal(net.online());

	watcher = new Effect(() -> {
	    var stop = Watch.changes(net, 1000, v -> online.value = v);
	    Effect.onCleanup(stop);
	});
	```

	The effect owns the watcher; `onCleanup` is how it gives it back. Nothing
	else in the application knows a timer exists — views read `online.value` and
	are re-applied when it changes, which is the ordinary reactive path.

	## Why the effect is created here and not in `body()`

	`body()` is called again on every rebuild. An effect created there would
	start a second watcher on the first rebuild, a third on the next, and each
	one would keep the last alive — the leak `onCleanup` prevents *within* an
	effect, reintroduced *around* it.

	So its life is the application's life, and that is stated by where it is
	created. `mui` exposes no view lifetime to attach it to instead, which is a
	real limit rather than an oversight: see the note in `rui`'s docs on why
	there is no `useEffect` here.
**/
class NetworkApp extends App {
	final net = kui.Kui.get(network.Network);

	var online:Signal<Bool>;
	var changes = new Signal(0);
	var watching = new Signal(true);

	public function new() {
		super();
		appTitle = "Network";

		online = new Signal(net.online());
		announce("start", online.peek());

		// Stop declaring the watcher after a while, so the release can be
		// watched happening rather than argued about.
		haxe.Timer.delay(() -> watching.value = false, 6000);
	}

	override function body():View {
		// A view lifetime, and the whole point of the key: this is only kept
		// alive while `body()` keeps declaring it. Press a key to stop watching
		// and the guard below stops asking — the watcher is undone at the start
		// of the next pass.
		if (watching.value) lifetime.keep("network", function() {
			var stop = network.Watch.changes(net, 1000, isOnline -> {
				online.value = isOnline;
				changes.value = changes.peek() + 1;
				announce("change", isOnline);
			});
			announce("kept", online.peek());
			return function() {
				stop();
				announce("released", online.peek());
			};
		});

		return new VStack([
			new Text("Watching the network", Title),
			new Text(online.value ? "online" : "offline"),
			new Text('changes seen: ${changes.value}'),
			new Text(watching.value ? "watching — press w to stop" : "stopped — press w to watch"),
		], 10);
	}

	// On stderr as well as on screen: a terminal backend takes the screen over,
	// and a change that happens while nobody is looking still has to be
	// checkable afterwards.
	static function announce(what:String, online:Bool):Void
		Sys.stderr().writeString('net: $what — ${online ? "online" : "offline"}\n');

	static function main() {
		#if mui_owns_main
		new NetworkApp().run();
		#end
	}
}
