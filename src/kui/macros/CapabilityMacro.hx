package kui.macros;

#if macro
import haxe.macro.Context;
import haxe.macro.Expr;
#end

/**
	What happens to every class that implements a capability.

	Runs from `@:autoBuild` on `kui.Capability`, so it fires for each
	implementation as it is built — which is also what gives `kui` a roster of them
	without walking the whole classpath.

	Three jobs:

	**Keep it.** An implementation's methods are only ever called through the
	declaration's interface, which is precisely what dead-code elimination exists
	to remove. `@:keep` is what earns its survival, and it is the same `@:keep`
	`qui.native.NativeModuleMacro` has always stamped.

	**Check it can be built.** `kui.Kui.instance` constructs through
	`Type.createInstance`, which the compiler cannot verify. A missing zero-argument
	constructor would be a runtime failure on one platform, found by whoever ships
	there — so it is checked here, at the class, where the fix is.

	**Turn `@:kuiNative` into `@:buildXml`.** The author states a native payload
	once, in one notation; hxcpp wants another. Synthesising it is safe — the probe
	in `probes/buildxml-through-macro` establishes that metadata added from inside
	a build macro reaches the generated `Build.xml` whole, survives `-dce full`,
	and survives the indirect shape `Kui.get` emits.

	That covers every link hxcpp performs. The four link steps it does not perform
	— qmake, Xcode, Gradle, MSBuild — never read `Build.xml`, and a `${haxelib:x}`
	path would reach them unexpanded even if they did. Those are served by the
	resolved sidecar `kui.macros.Emit` writes, from the same payload.
**/
class CapabilityMacro {
	public static macro function build():Array<Field> {
		var fields = Context.getBuildFields();
		#if macro
		var cls = Context.getLocalClass();
		if (cls == null) return fields;
		var type = cls.get();

		// An interface extending Capability is a declaration, not an
		// implementation: nothing to keep, construct or link.
		if (type.isInterface) return fields;

		if (!type.meta.has(":keep")) type.meta.add(":keep", [], type.pos);

		requireConstructor(fields, type);
		attachPayload(type);
		#end
		return fields;
	}

	#if macro
	static function requireConstructor(fields:Array<Field>, type:haxe.macro.Type.ClassType):Void {
		for (field in fields) {
			if (field.name != "new") continue;
			switch (field.kind) {
				case FFun(f) if (f.args.length == 0): return;
				case FFun(_):
					Context.error("kui constructs a capability itself, so "
						+ type.name + " needs a constructor taking no arguments.", field.pos);
					return;
				case _:
			}
			return;
		}
		Context.error("kui constructs a capability itself, so " + type.name
			+ ' needs "public function new() {}".', type.pos);
	}

	/**
		Read `@:kuiNative`, type it, and emit the hxcpp half as `@:buildXml`.

		Paths are resolved against the **library root** — the directory holding
		`haxelib.json`, found by walking up from the class's own file. A path
		relative to the working directory is what stopped `qui`'s native modules
		from ever coming out of a haxelib, and it is not repeated here.
	**/
	static function attachPayload(type:haxe.macro.Type.ClassType):Void {
		var declared = type.meta.extract(":kuiNative");
		if (declared.length == 0) return;
		if (declared[0].params.length != 1) {
			Context.error("@:kuiNative takes one object, as in "
				+ "@:kuiNative({hxcpp: {files: [\"native/x.cpp\"]}})", declared[0].pos);
			return;
		}

		var literal = declared[0].params[0];
		// Typed before it is read, so a misspelled field is an error here rather
		// than a key quietly ignored three build steps later.
		Context.typeof(macro ($literal : kui.build.Payload));

		var root = libraryRoot(type);
		var hxcpp = fieldOf(literal, "hxcpp");
		if (hxcpp == null) return;

		var xml = new StringBuf();
		var files = strings(fieldOf(hxcpp, "files"));
		var includes = strings(fieldOf(hxcpp, "includes"));
		var flags = strings(fieldOf(hxcpp, "flags"));
		var libs = strings(fieldOf(hxcpp, "libs"));

		if (files.length > 0 || includes.length > 0 || flags.length > 0) {
			xml.add('<files id="haxe">');
			for (include in includes) xml.add('<compilerflag value="-I' + root + "/" + include + '" />');
			for (flag in flags) xml.add('<compilerflag value="' + flag + '" />');
			for (file in files) xml.add('<file name="' + root + "/" + file + '" />');
			xml.add("</files>");
		}
		if (libs.length > 0) {
			xml.add('<target id="haxe">');
			for (lib in libs) xml.add('<lib name="' + lib + '" />');
			xml.add("</target>");
		}

		var fragment = xml.toString();
		if (fragment != "") type.meta.add(":buildXml", [macro $v{fragment}], type.pos);
	}

	/**
		The directory holding the library's `haxelib.json`.

		Walked up from the class's own source file, so it works the same whether
		the capability came from `-lib` or from a local `capabilities/` directory —
		which is what "distributable both ways" means in practice.
	**/
	static function libraryRoot(type:haxe.macro.Type.ClassType):String {
		var at = try haxe.io.Path.directory(Context.getPosInfos(type.pos).file) catch (_:Dynamic) "";
		if (at != "" && !haxe.io.Path.isAbsolute(at)) at = sys.FileSystem.absolutePath(at);
		var here = at;
		while (here != "" && here != "/") {
			if (sys.FileSystem.exists(here + "/haxelib.json")) return here;
			var up = haxe.io.Path.directory(here);
			if (up == here) break;
			here = up;
		}
		// No haxelib.json above it: a local capability, whose paths are relative
		// to wherever it sits.
		return at;
	}

	static function fieldOf(e:Expr, name:String):Null<Expr> {
		return switch (e.expr) {
			case EObjectDecl(fields):
				var found = null;
				for (field in fields) if (field.field == name) found = field.expr;
				found;
			case _: null;
		}
	}

	static function strings(e:Null<Expr>):Array<String> {
		if (e == null) return [];
		return switch (e.expr) {
			case EArrayDecl(values): [
					for (value in values)
						switch (value.expr) {
							case EConst(CString(s)): s;
							case _: Context.error("kui: expected a string", value.pos);
						}
				];
			case _: [];
		}
	}
	#end
}
