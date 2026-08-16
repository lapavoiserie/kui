package kui.build;

/**
	Reading `kui-payload.json`, for whoever performs the link.

	Every consumer wants the same thing — the union of one section across every
	capability in the build — and none of them should have to parse JSON to get
	it. A generator written in Haxe calls this directly; a shell script calls
	`haxelib run kui payload`, which is this class with an argument parser in
	front.

	```haxe
	var payload = kui.build.Sidecar.read("build/sui");
	for (framework in payload.strings("xcode", "frameworks")) …
	```

	**A build with no capabilities is the ordinary case.** `read` answers with an
	empty payload rather than failing, so a consumer adds its hook unconditionally
	and nothing changes for a project that uses none.
**/
class Sidecar {
	final document:Dynamic;

	function new(document:Dynamic) {
		this.document = document;
	}

	/** The sidecar in a directory, or an empty one if there is none. **/
	public static function read(directory:String):Sidecar {
		var path = directory + "/kui-payload.json";
		if (!sys.FileSystem.exists(path)) return new Sidecar({capabilities: []});
		return try new Sidecar(haxe.Json.parse(sys.io.File.getContent(path)))
			catch (_:Dynamic) new Sidecar({capabilities: []});
	}

	/**
		The same reader over payloads still held in memory.

		For a generator that runs **inside the compilation** rather than after it —
		`aui`'s `GradleProject`, `wui`'s `ProjectGenerator`. Those hook
		`Context.onAfterGenerate` just as `kui.macros.Emit` does, and the order two
		such callbacks run in is the order they were registered: a backend's
		`--macro …register()` line runs at initialisation, before any capability has
		been built, so the backend's callback is always registered first and always
		runs first. It would read a sidecar that does not exist yet.

		So an in-process consumer asks `kui.macros.Emit.current()` for this, and only
		a separate process — `sui`'s CLI, a `.pro`, a shell script — reads the file.
		Same class either way, so knowing one is knowing the other.
	**/
	public static function of(capabilities:Array<Dynamic>):Sidecar
		return new Sidecar({capabilities: capabilities});

	/** Whether anything at all declared a payload. **/
	public function any():Bool
		return capabilities().length > 0;

	/** What the build is for, as `kui` resolved it. **/
	public function platform():Null<String>
		return Reflect.field(document, "platform");

	/**
		Every value of one field of one toolchain, across every capability, in
		declaration order and without duplicates.

		Deduplicated because two capabilities may want the same framework, and a
		link line that names `IOKit` twice is a link line someone will one day try
		to explain.
	**/
	public function strings(toolchain:String, field:String):Array<String> {
		var out = [];
		for (capability in capabilities()) {
			var section = Reflect.field(Reflect.field(capability, "payload"), toolchain);
			if (section == null) continue;
			var values:Array<String> = Reflect.field(section, field);
			if (values == null) continue;
			for (value in values) if (out.indexOf(value) < 0) out.push(value);
		}
		return out;
	}

	/** The same, for a field whose entries are objects — a package, a NuGet id. **/
	public function objects(toolchain:String, field:String):Array<Dynamic> {
		var out = [];
		for (capability in capabilities()) {
			var section = Reflect.field(Reflect.field(capability, "payload"), toolchain);
			if (section == null) continue;
			var values:Array<Dynamic> = Reflect.field(section, field);
			if (values == null) continue;
			for (value in values) out.push(value);
		}
		return out;
	}

	/** Who declared what, for a message that names the capability. **/
	public function names():Array<String>
		return [for (capability in capabilities()) Reflect.field(capability, "type")];

	function capabilities():Array<Dynamic> {
		var list:Array<Dynamic> = Reflect.field(document, "capabilities");
		return list == null ? [] : list;
	}
}
