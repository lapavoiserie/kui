package kui;

import haxe.macro.Context;
import haxe.macro.Expr;

class Kui {
	/** The reflective hop qui proves routes through CPPIA. **/
	public static function instance<T:Capability>(cls:Class<T>):T {
		return cast Type.createInstance(cls, []);
	}

	/** `Kui.get(battery.Battery)` — resolves the platform's implementation. **/
	public static macro function get(declaration:Expr):Expr {
		var path = exprPath(declaration);
		var platform = Context.definedValue("kui_platform");
		var parts = path.split(".");
		var name = parts.pop();
		var impl = parts.concat(["platform", platform, name]).join(".");

		if ((try Context.getType(impl) catch (_:Dynamic) null) == null)
			Context.error('$path has no implementation for "$platform" (looked for $impl)',
				Context.currentPos());

		var implExpr = macro $p{impl.split(".")};
		var declared = TPath({pack: parts, name: name});
		return macro (kui.Kui.instance($implExpr) : $declared);
	}

	#if macro
	static function exprPath(e:Expr):String {
		return switch (e.expr) {
			case EConst(CIdent(s)): s;
			case EField(sub, f): exprPath(sub) + "." + f;
			case _: Context.error("expected a type path", e.pos);
		}
	}
	#end
}
