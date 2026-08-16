import haxe.macro.Context;

class Add {
	public static macro function build():Array<haxe.macro.Expr.Field> {
		var cls = Context.getLocalClass().get();
		if (!cls.meta.has(":keep")) cls.meta.add(":keep", [], Context.currentPos());
		var fragment = '<files id="haxe"><file name="/spike/native/battery_mac.mm" /></files>'
			+ '<target id="haxe"><lib name="-framework" /><lib name="IOKit" /></target>';
		cls.meta.add(":buildXml", [macro $v{fragment}], Context.currentPos());
		return Context.getBuildFields();
	}
}
