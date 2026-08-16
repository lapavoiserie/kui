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
		guardReservedNames(type);
		attachPayload(type);
		#end
		return fields;
	}

	#if macro
	/**
		The package names a C compiler has already taken.

		GCC and clang define `linux`, `unix` and `i386` as `1` outside strict ISO
		mode, and Haxe turns a package into a C++ namespace verbatim. So an
		implementation at `battery.platform.linux.Battery` generates
		`namespace battery{ namespace platform{ namespace linux{` — which the
		preprocessor rewrites to `namespace 1{` before the compiler ever sees it.
		The error is "expected identifier before numeric constant", at a line that
		looks perfectly ordinary, in a file nobody wrote.

		This is `kui`'s problem and not the author's: `kui` chose `linux` as a
		platform id, and the convention `p.platform.<id>.Name` follows from that.
		So `kui` undefines them, for the whole program rather than for one file —
		the collision is in the *generated* sources, which name the namespace from
		every file that reaches the capability.

		Undefining is what strict ISO mode does anyway. Code that tests for Linux
		portably uses `__linux__`, which is untouched.
	**/
	static final RESERVED = ["linux", "unix", "i386"];

	static function reservedIn(type:haxe.macro.Type.ClassType):Array<String> {
		var found = [];
		for (part in type.pack)
			if (RESERVED.indexOf(part) >= 0 && found.indexOf(part) < 0) found.push(part);
		return found;
	}

	/** Tell `Emit` too, so the qmake fragment carries the same flags. **/
	static function guardReservedNames(type:haxe.macro.Type.ClassType):Void {
		var found = reservedIn(type);
		if (found.length > 0) Emit.undefine(found);
	}

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
		// Emitted whether or not there is a payload: an implementation for a
		// reserved package name breaks the build on its own, with nothing native
		// in it at all.
		var undefs = new StringBuf();
		var reserved = reservedIn(type);
		if (reserved.length > 0) {
			undefs.add('<files id="haxe">');
			for (name in reserved) undefs.add('<compilerflag value="-U' + name + '" />');
			undefs.add("</files>");
		}

		var declared = type.meta.extract(":kuiNative");
		if (declared.length == 0) {
			if (reserved.length > 0)
				type.meta.add(":buildXml", [macro $v{undefs.toString()}], type.pos);
			return;
		}
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

		// The whole payload, every path resolved, for the four link steps that
		// read the sidecar rather than Build.xml.
		var name = type.pack.concat([type.name]).join(".");
		Emit.record(name, resolved(literal, root));

		var hxcpp = fieldOf(literal, "hxcpp");
		if (hxcpp == null) return;

		var xml = new StringBuf();
		var files = strings(fieldOf(hxcpp, "files"));
		var includes = strings(fieldOf(hxcpp, "includes"));
		var flags = strings(fieldOf(hxcpp, "flags"));
		var libs = strings(fieldOf(hxcpp, "libs"));

		// A group of its own, never `<files id="haxe">`. Two reasons, and the
		// first one is not a matter of taste:
		//
		// hxcpp's own group carries `<precompiledheader name="hxcpp">`, and under
		// MSVC every file in a group with a precompiled header must include it.
		// A capability's C++ has no reason to include `hxcpp.h`, and adding it to
		// that group fails the build with "unexpected end of file while looking
		// for precompiled header" — an error that names the capability's file and
		// explains nothing about why it is being asked for hxcpp's header.
		//
		// And a `compilerflag` in that group applies to **every** generated Haxe
		// source. One capability's `-I` would reach all of them, which is
		// harmless until two capabilities disagree, and a `flags` entry would be
		// applied to the whole program by a declaration that reads as local.
		var group = "kui_" + name.split(".").join("_");
		if (files.length > 0 || includes.length > 0 || flags.length > 0) {
			xml.add('<files id="' + group + '">');
			for (include in includes) xml.add('<compilerflag value="-I' + root + "/" + include + '" />');
			for (flag in flags) xml.add('<compilerflag value="' + flag + '" />');
			for (file in files) xml.add('<file name="' + root + "/" + file + '" />');
			xml.add("</files>");
		}
		if (files.length > 0 || includes.length > 0 || flags.length > 0 || libs.length > 0) {
			xml.add('<target id="haxe">');
			if (files.length > 0) xml.add('<files id="' + group + '" />');
			for (lib in libs) xml.add('<lib name="' + lib + '" />');
			xml.add("</target>");
		}

		var fragment = undefs.toString() + xml.toString();
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

	/**
		The payload as plain data, with every path made absolute.

		Which fields are paths is stated rather than guessed: `files`, `includes`
		and `sources` name things on disk, and everything else — a framework, a
		Gradle coordinate, a `pkgconfig` name — is a token the build system
		resolves itself. Resolving those would turn `IOKit` into a directory that
		does not exist.
	**/
	static final PATHS = ["files", "includes", "sources"];

	static function resolved(literal:Expr, root:String):Dynamic {
		var out:Dynamic = {};
		switch (literal.expr) {
			case EObjectDecl(sections):
				for (section in sections) {
					var content:Dynamic = {};
					switch (section.expr.expr) {
						case EObjectDecl(entries):
							for (entry in entries) {
								var values = strings(entry.expr);
								if (values.length > 0 || isStringArray(entry.expr)) {
									Reflect.setField(content, entry.field,
										PATHS.indexOf(entry.field) >= 0
											? [for (v in values) absolute(root, v)] : values);
								} else {
									// An array of objects — a NuGet package, an SPM
									// coordinate. Carried through as written.
									Reflect.setField(content, entry.field, objects(entry.expr));
								}
							}
						case _:
					}
					Reflect.setField(out, section.field, content);
				}
			case _:
		}
		return out;
	}

	static function absolute(root:String, path:String):String
		return haxe.io.Path.isAbsolute(path) ? path : root + "/" + path;

	static function isStringArray(e:Expr):Bool {
		return switch (e.expr) {
			case EArrayDecl(values): values.length == 0
					|| switch (values[0].expr) { case EConst(CString(_)): true; case _: false; };
			case _: false;
		}
	}

	static function objects(e:Expr):Array<Dynamic> {
		return switch (e.expr) {
			case EArrayDecl(values): [
					for (value in values)
						switch (value.expr) {
							case EObjectDecl(fields):
								var made:Dynamic = {};
								for (field in fields)
									switch (field.expr.expr) {
										case EConst(CString(s)): Reflect.setField(made, field.field, s);
										case _:
									}
								made;
							case _: ({}:Dynamic);
						}
				];
			case _: [];
		}
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
