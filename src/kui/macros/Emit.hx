package kui.macros;

#if macro
import haxe.macro.Context;
import haxe.macro.Expr;
#end

/**
	What every link step that is not hxcpp reads.

	## Why a second artefact at all

	`@:buildXml` is enough where hxcpp performs the link, and the probe in
	`probes/buildxml-through-macro` shows it survives everything — including
	`-dce full` and metadata added from inside a build macro.

	It is enough **nowhere else**, and the reason is not that the metadata is
	lost. Haxe writes a complete `Build.xml` even under `-D no-compilation`; the
	fragments are in it, verbatim. The trouble is that the four remaining link
	steps never open that file — qmake globs its sources, the iOS and Android
	scripts hardcode theirs, and Xcode, Gradle and MSBuild projects are generated
	from scratch on every build. And a path written `${haxelib:x}` would reach
	them unexpanded even if they did read it, because only hxcpp's own build tool
	expands that.

	So `kui` writes `kui-payload.json` beside the generated output: the same
	payloads, every path already absolute, in a form a shell script, a `.pro`, a
	Gradle file or a `.vcxproj` can consume without knowing anything about Haxe.

	## Nothing has to ask for it

	The first implementation that carries a payload registers the writer. A build
	with no capabilities writes no file, and a build step that finds none does
	nothing — which is what lets every consumer add its hook unconditionally.
**/
class Emit {
	#if macro
	static var payloads:Array<{type:String, platform:String, payload:Dynamic}> = [];
	static var undefs:Array<String> = [];
	static var armed = false;

	/**
		Names the C preprocessor has already taken, found in a capability's
		package by `CapabilityMacro`.

		Recorded here as well as stamped as `@:buildXml`, because the two
		compilers that matter read different things: hxcpp reads the metadata,
		qmake reads the `.pri`. The same `-U` has to reach both, and a build with
		no native payload at all still needs it — the collision is in the
		generated namespace, not in anything the author wrote.
	**/
	public static function undefine(names:Array<String>):Void {
		for (name in names) if (undefs.indexOf(name) < 0) undefs.push(name);
		arm();
	}

	/** Every name to undefine, for whoever renders a build fragment. **/
	public static function undefined():Array<String>
		return undefs.copy();

	/** Called by `CapabilityMacro` for each implementation it builds. **/
	public static function record(type:String, payload:Dynamic):Void {
		payloads.push({
			type: type,
			platform: Host.platform() == null ? "" : Host.platform(),
			payload: payload,
		});
		arm();
	}

	static function arm():Void {
		if (armed) return;
		armed = true;
		Context.onAfterGenerate(write);
	}

	/**
		Every payload declared so far, for a generator running in this compilation.

		`aui` writes `build.gradle.kts` and `wui` a `.vcxproj` from
		`Context.onAfterGenerate`, the same hook `write` uses — and theirs is
		registered first, from the `--macro` line, so by the time they run the
		sidecar has not been written. They ask here instead and get the same reader
		over the same data.

		Called from a generator's callback, i.e. after typing, so the roster is
		complete. Called earlier it would answer with whatever had been built by
		then, which is why nothing calls it earlier.
	**/
	public static function current():kui.build.Sidecar
		return kui.build.Sidecar.of(cast payloads);

	static function write():Void {
		if (payloads.length == 0 && undefs.length == 0) return;

		var out = haxe.macro.Compiler.getOutput();
		// `-cpp out` names a directory; a single-file target names the file.
		var directory = sys.FileSystem.exists(out) && sys.FileSystem.isDirectory(out)
			? out : haxe.io.Path.directory(out);
		if (directory == "") directory = ".";

		var document = {
			platform: Host.platform(),
			backend: Host.backend(),
			toolchains: Host.toolchains(),
			capabilities: payloads,
		};

		try {
			if (!sys.FileSystem.exists(directory)) sys.FileSystem.createDirectory(directory);
			sys.io.File.saveContent(directory + "/kui-payload.json",
				haxe.Json.stringify(document, null, "  "));

			// qmake gets a rendering of its own — and a copy of the sources,
			// because it runs inside a container where the host's paths do not
			// exist. See `kui.build.Qmake`.
			kui.build.Qmake.write(current(), directory, undefs);
		} catch (e:Dynamic) {
			// A build that cannot write its sidecar must say so rather than link
			// half a capability: the native code would be missing and the Haxe
			// side would compile, which is the worst of both.
			Context.warning("kui could not write kui-payload.json to " + directory
				+ ": " + Std.string(e), Context.currentPos());
		}
	}
	#end
}
