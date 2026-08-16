class Check {
	static function main() {
		var b = kui.Kui.get(battery.Battery);
		Sys.println("level " + b.level());
		Sys.println("supports " + kui.Kui.supports(battery.Battery));
	}
}
