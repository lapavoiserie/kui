package battery.platform.android;

/**
	Android, through a Kotlin object compiled by Gradle.

	The link step here is neither hxcpp nor a linker at all: `aui` compiles Haxe
	to a JAR and **Gradle** builds the APK around it. So the payload names Kotlin
	sources and a Maven coordinate rather than object files and frameworks, and
	`aui.macros.GradleProject` renders them into `build.gradle.kts` — the source
	directory into `sourceSets`, the coordinate into `dependencies`.

	The sources are named relative to the library root and `kui` resolves them to
	absolute, which is what lets Gradle compile the Kotlin **where it lives**
	instead of requiring it to be copied into the generated Android tree. A
	capability shipped as a haxelib therefore works without being unpacked, which
	is exactly what `qui`'s working-directory-relative `modules/native` scan could
	never do.
**/
@:kuiNative({
	gradle: {
		sources: ["native/BatteryAndroid.kt"],
		// Genuinely needed to compile the Kotlin, not declared for the sake of
		// exercising the field: `@Keep` is what stops R8 from removing methods
		// that are only ever reached by name from Haxe.
		dependencies: ["androidx.annotation:annotation:1.9.1"],
	},
})
class Battery implements battery.Battery {
	public function new() {}

	public function level():Int
		return BatteryNative.level();

	public function charging():Bool
		return BatteryNative.charging();
}

/**
	The Kotlin object, named rather than seen.

	Haxe never reads the Kotlin: the JAR it produces and the Kotlin Gradle
	compiles are two separate compilations that only meet inside the APK. An
	extern is the honest description of that — a name and a signature, resolved at
	runtime — and it is also why a typo here is an error on the device rather than
	at compile time. Keeping the extern in the same module as its only caller is
	what makes the two easy to keep in step.
**/
@:native("kui.example.BatteryNative")
extern class BatteryNative {
	static function level():Int;
	static function charging():Bool;
}
