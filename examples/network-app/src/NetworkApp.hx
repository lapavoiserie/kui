import mui.App;
import mui.View;
import mui.ui.Text;
import mui.ui.VStack;
import mui.ui.Button;
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

	// `@:state`, not a raw `rui.Signal`: a write to mui's own state is what
	// invalidates the tree and gets `body()` re-run on every backend. A bare
	// signal is read fine but nothing asks for a rebuild, so the declaration
	// never changes and `keep` never sweeps.
	@:state var online:Bool = false;
	@:state var changes:Int = 0;
	@:state var watching:Bool = true;

	public function new() {
		super();
		appTitle = "Network";

		announce("start", net.online());

		// Two ways to stop declaring the watcher, because two kinds of machine
		// run this. A timer where one can exist, so a scripted run verifies
		// itself; and a button, for a device where nobody is watching a
		// terminal — and where, today, a timer cannot be had at all.
		try haxe.Timer.delay(() -> watching.set(false), 6000)
		catch (e:Dynamic) announce("no timer here", true);
	}

	override function body():View {
		// A view lifetime, and the whole point of the key: this is only kept
		// alive while `body()` keeps declaring it. Press a key to stop watching
		// and the guard below stops asking — the watcher is undone at the start
		// of the next pass.
		if (watching.get()) lifetime.keep("network", function() {
			// Watching needs a timer. Where the host thread has no Haxe event
			// loop — SailfishOS, whose thread Qt created — there is none to be
			// had, and saying so beats crashing: the reading is still taken, and
			// what is being demonstrated here is the lifetime, not the polling.
			var stop:Null<Void->Void> = null;
			try stop = network.Watch.changes(net, 1000, isOnline -> {
				online.set(isOnline);
				changes.set(changes.get() + 1);
				announce("change", isOnline);
			}) catch (e:Dynamic) announce("kept without a watcher", true);
			// Read once at the start: `Watch` reports *changes*, so without this
			// the first display would show the declared default rather than the
			// machine.
			online.set(net.online());
			announce("kept", online.get());
			return function() {
				if (stop != null) stop();
				announce("released", online.get());
			};
		});

		return new VStack([
			new Text("Watching the network", Title),
			new Text(online.get() ? "online" : "offline"),
			new Text('changes seen: ${changes.get()}'),
			new Text(watching.get() ? "watching" : "stopped watching"),
			new Button(watching.get() ? "stop watching" : "watch", () -> watching.set(!watching.get())),
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
