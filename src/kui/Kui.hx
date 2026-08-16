package kui;

#if macro
import haxe.macro.Context;
import haxe.macro.Expr;
import kui.macros.Host;
#end

/**
	How an application reaches a native capability.

	```haxe
	var battery = kui.Kui.get(battery.Battery);
	trace(battery.level());
	```

	`get` resolves `battery.platform.<id>.Battery` for the platform being built and
	returns it typed as the declaration — so autocompletion, arity and return types
	all come from `battery.Battery`, and nothing is `Dynamic`.

	## Why `get` is a macro

	`qui.native.Native.get(cls:Class<T>):T` is the proven shape and it does not
	survive the move to interfaces: `Class<T>` cannot be written for an interface
	in Haxe. Taking the type path as an expression instead costs nothing at the
	call site and buys something real — a capability with no implementation for
	this platform becomes a **compile error naming both**, where the older shape
	could only have returned `null`.

	## Why `instance` still goes through reflection

	`Type.createInstance` is what `qui` has always done, and it is what makes an
	interpreted CPPIA guest route to the host's compiled class. Replacing it with
	a direct `new` looks like an obvious improvement and is not one to be made
	without measuring on a Sailfish device first.
**/
class Kui {
	static var made:Map<String, Capability> = new Map();

	/**
		The cached instance of an implementation class.

		Not for applications — `get` emits the call. One instance per class, for
		the same reason `qui` does: a capability usually wraps something the
		platform has exactly one of.
	**/
	public static function instance<T:Capability>(cls:Class<T>):T {
		var key = Type.getClassName(cls);
		var already = made.get(key);
		if (already == null) {
			already = cast Type.createInstance(cls, []);
			made.set(key, already);
		}
		return cast already;
	}

	/** The platform's implementation of a capability, typed as the declaration. **/
	public static macro function get(declaration:Expr):Expr {
		var path = pathOf(declaration);
		var platform = requirePlatform(declaration.pos);
		var implementation = implementationOf(path, platform);

		if (resolve(implementation) == null) {
			Context.error(missing(path, platform, implementation), declaration.pos);
			return macro null;
		}

		var parts = path.split(".");
		var name = parts.pop();
		var declared = TPath({pack: parts, name: name});
		var implExpr = macro $p{implementation.split(".")};
		return macro (kui.Kui.instance($implExpr) : $declared);
	}

	/**
		Whether this platform implements a capability — a compile-time constant.

		Folds to `true` or `false`, so the branch that cannot work is removed
		rather than reached:

		```haxe
		if (Kui.supports(battery.Battery)) show(Kui.get(battery.Battery).level());
		```

		This is the honest escape valve for a feature that is genuinely optional.
		It is not a way to make a missing capability quiet: reaching for one
		without asking is still an error, because the alternative is an
		application that silently does less on one platform and nobody notices.
	**/
	public static macro function supports(declaration:Expr):Expr {
		var platform = Host.platform();
		if (platform == null) return macro false;
		var implementation = implementationOf(pathOf(declaration), platform);
		return resolve(implementation) == null ? macro false : macro true;
	}

	#if macro
	/** `battery.Battery` on `macos` → `battery.platform.macos.Battery`. **/
	static function implementationOf(path:String, platform:String):String {
		var parts = path.split(".");
		var name = parts.pop();
		return parts.concat(["platform", platform, name]).join(".");
	}

	/**
		The implementation, or `null` when there is genuinely none.

		Only "type not found" counts as absent. Anything else — most often the
		implementation's own build macro refusing it, for a constructor `kui`
		cannot call — is **rethrown**, because swallowing it reports a class that
		exists and is broken as a class that does not exist. The author would then
		be told to write a file they had already written.
	**/
	static function resolve(path:String):Null<haxe.macro.Type> {
		return try Context.getType(path) catch (e:Dynamic) {
			var message = Std.string(e);
			if (StringTools.startsWith(message, "Type not found")) null else throw e;
		}
	}

	static function pathOf(e:Expr):String {
		return switch (e.expr) {
			case EConst(CIdent(name)): name;
			case EField(sub, field): pathOf(sub) + "." + field;
			case _:
				Context.error("kui: expected a capability's type path, as in "
					+ "Kui.get(battery.Battery)", e.pos);
				"";
		}
	}

	static function requirePlatform(pos:Position):String {
		var platform = Host.platform();
		if (platform == null) {
			Context.error("kui does not know which platform this build targets.\n"
				+ "  A backend states it — add \"--macro <backend>.kui.Platform.registerWithKui()\"\n"
				+ "  to your build file — or set -D kui_platform=<id>.\n"
				+ "  Known: " + Platforms.ids().join(", "), pos);
			return "";
		}
		if (!Platforms.known(platform) && !Context.defined("kui_platform_unchecked")) {
			Context.error('kui does not know the platform "$platform".\n'
				+ "  Known: " + Platforms.ids().join(", ") + "\n"
				+ "  If that is deliberate, build with -D kui_platform_unchecked.", pos);
			return "";
		}
		return platform;
	}

	/**
		The message for a capability this platform does not implement.

		It names three things, because each answers a different question: what was
		asked for, what this build is, and where `kui` looked — the last being what
		turns "it does not work" into a file to create.

		What the capability *does* implement is read off the filesystem, beside the
		declaration. Derived rather than declared, so it cannot drift; and used for
		the message only, since the check itself is `Context.getType` and a stale
		directory must not be able to approve anything.
	**/
	static function missing(path:String, platform:String, implementation:String):String {
		var message = '$path has no implementation for "$platform".';
		var covered = implemented(path);
		if (covered.length > 0) message += "\n  It implements: " + covered.join(", ") + ".";
		return message + '\n  kui looked for $implementation.';
	}

	static function implemented(path:String):Array<String> {
		return try {
			var file = Context.resolvePath(path.split(".").join("/") + ".hx");
			var beside = haxe.io.Path.directory(file) + "/platform";
			if (!sys.FileSystem.exists(beside)) [] else {
				var found = [
					for (entry in sys.FileSystem.readDirectory(beside))
						if (sys.FileSystem.isDirectory(beside + "/" + entry)) entry
				];
				found.sort(Reflect.compare);
				found;
			}
		} catch (_:Dynamic) [];
	}
	#end
}
