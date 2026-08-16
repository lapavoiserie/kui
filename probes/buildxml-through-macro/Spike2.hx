class Spike2 {
	static function main() {
		var b = kui.Kui.get(battery.Battery);
		Sys.println("level " + b.level());
	}
}
