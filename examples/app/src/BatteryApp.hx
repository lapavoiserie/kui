import mui.App;
import mui.View;
import mui.ui.Text;
import mui.ui.VStack;

/**
	The same application, the same capability, two backends.

	Nothing here names a platform or a backend. `kui.Kui.get` resolves
	`battery.platform.macos.Battery` because that is what this build is for — and
	the implementation it resolves to was written for no backend in particular,
	which is the whole point.
**/
class BatteryApp extends App {
	public function new() {
		super();
		appTitle = "Battery";
	}

	override function body():View {
		var battery = kui.Kui.get(battery.Battery);
		var level = battery.level();
		announce();

		return new VStack([
			new Text("A capability, through mui", Title),
			new Text(level < 0 ? "no battery on this machine" : 'charge: $level %'),
			new Text(supply(battery, level)),
		], 10);
	}

	/**
		Four states, because two lied and three contradicted the line above.

		This line first read `charging() ? "charging" : "on battery"`, and it told
		a laptop plugged in at 100 % that it was running on battery — the battery
		is *charged*, not *charging*, so the flag is false with the cable in the
		wall. The bug was not in the native code, which answered exactly what it
		was asked; it was a question with two answers where the world has more.

		Three answers were still not enough, and the machine that showed it was an
		iOS simulator: `level()` said -1, so the line above read "no battery on
		this machine", while this one read "on battery". Both from the same
		object, in the same frame.

		So the two facts are read together. `level() < 0` means there is no
		reading, and what that means depends on whether the mains is connected: a
		desktop is on mains power, and a machine that cannot tell either way says
		so rather than picking the reassuring one.
	**/
	static function supply(battery:battery.Battery, level:Int):String {
		if (!battery.powered()) return level < 0 ? "power source unknown" : "on battery";
		if (level < 0) return "on mains power";
		return battery.charging() ? "charging" : "plugged in, not charging";
	}

	/**
		The reading, on stderr, once.

		Said in writing as well as on screen because the point of this example is
		the capability rather than the picture: a terminal backend takes the screen
		over the moment it starts, and a windowed one cannot be read from a script.

		Called from **both** entry points, and that is the interesting part. A
		backend that owns `main` — `pui`, `cui` — reaches it through `main`; `sui`
		never runs the Haxe `main` at all. Its Swift side boots the runtime through
		`viewnode_boot` and asks for the view tree, so `body` is the only Haxe an
		application is guaranteed to reach. Announcing from one place only would
		have looked like the capability was not running.
	**/
	static var announced = false;

	static function announce():Void {
		if (announced) return;
		announced = true;
		var battery = kui.Kui.get(battery.Battery);
		var level = battery.level();
		Sys.stderr().writeString('kui: level $level, ' + supply(battery, level) + "\n");
	}

	static function main() {
		announce();

		#if mui_owns_main
		new BatteryApp().run();
		#end
	}
}
