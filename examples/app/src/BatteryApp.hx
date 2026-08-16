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

		return new VStack([
			new Text("A capability, through mui", Title),
			new Text(level < 0 ? "no battery on this machine" : 'charge: $level %'),
			new Text(battery.charging() ? "charging" : "on battery"),
		], 10);
	}

	static function main() {
		// Said on stderr before anything draws, because the point of this example
		// is the capability rather than the picture — and a terminal backend takes
		// the screen over the moment it starts.
		var battery = kui.Kui.get(battery.Battery);
		Sys.stderr().writeString('kui: level ${battery.level()}, charging '
			+ battery.charging() + "\n");

		#if mui_owns_main
		new BatteryApp().run();
		#end
	}
}
