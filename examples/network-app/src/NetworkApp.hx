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
	var watcher:Effect;

	public function new() {
		super();
		appTitle = "Network";

		online = new Signal(net.online());
		announce("start", online.peek());

		watcher = new Effect(() -> {
			var stop = network.Watch.changes(net, 1000, isOnline -> {
				online.value = isOnline;
				changes.value = changes.peek() + 1;
				announce("change", isOnline);
			});
			Effect.onCleanup(() -> {
				stop();
				announce("stopped", online.peek());
			});
		});
	}

	/** Give the watcher back. Idempotent, because `dispose()` is. **/
	public function stopWatching():Void
		watcher.dispose();

	override function body():View {
		return new VStack([
			new Text("Watching the network", Title),
			new Text(online.value ? "online" : "offline"),
			new Text('changes seen: ${changes.value}'),
		], 10);
	}

	// On stderr as well as on screen: a terminal backend takes the screen over,
	// and a change that happens while nobody is looking still has to be
	// checkable afterwards.
	static function announce(what:String, online:Bool):Void
		Sys.stderr().writeString('net: $what — ${online ? "online" : "offline"}\n');

	static function main() {
		#if mui_owns_main
		var app = new NetworkApp();
		app.run();
		app.stopWatching();
		#end
	}
}
