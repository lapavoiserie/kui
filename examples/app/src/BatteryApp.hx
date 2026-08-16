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
			new Text(battery.charging() ? "charging" : "on battery"),
		], 10);
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
		Sys.stderr().writeString('kui: level ${battery.level()}, charging '
			+ battery.charging() + "\n");
	}

	static function main() {
		announce();

		#if mui_owns_main
		new BatteryApp().run();
		#end
	}
}
