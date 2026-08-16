package kui.macros;

#if macro
import haxe.macro.Context;
#end

/**
	What a backend tells `kui` about the build it is producing.

	A `kui` capability is keyed by platform, so `kui` has to know which one is
	being built. It cannot work that out on its own, and the reason is worth
	stating because it decided the mechanism.

	## Why registration rather than resolution

	Everywhere else in this ecosystem a macro resolves things **by name**:
	`mui.macros.Bind` is handed `"pui"` and looks up `pui.mui.Button`. That works
	because the answer is a *type*.

	Here the answer is a fact only the backend holds, and holds in its own terms.
	`pui` compiles SailfishOS and desktop Linux from the same `-D pui_surface=qt`
	— the only thing separating them is `DEFINES += PUI_SAILFISH` in a `.pro`
	file, which no Haxe macro can see. `sui` covers macOS, iOS and visionOS off
	three of its own defines. `cui` runs wherever it was compiled.

	Mapping those to a platform is the backend's knowledge, and a `#if` ladder for
	it inside `kui` would be exactly what `mui` spent a day deleting. So the
	backend declares itself, from its own build file:

	```
	--macro pui.kui.Platform.registerWithKui()
	```

	the same shape `mui.macros.Backend.register` takes, and for the same reason a
	macro cannot call a function it was only handed the name of.

	## An explicit define always wins

	`-D kui_platform=sailfish` overrides whatever a backend registered, and on Qt
	builds it is **required**: today `build-pui-sailfish.hxml` and
	`build-pui-linux.hxml` are identical in Haxe terms, so nothing else can tell
	them apart.

	## Absence is not approval

	A build where nobody registered and nothing was defined does not get a
	default. `Kui.get` refuses and says how to fix it — the rule
	`mui.macros.Backend.hasVocabulary()` already follows, for the same reason a
	schema that accepts everything is a schema that checks nothing.
**/
typedef Declaration = {
	/** A `kui.Platforms` id. **/
	var platform:String;

	/**
		Which link steps this build has: `hxcpp`, `qmake`, `xcode`, `gradle`,
		`msbuild`. One platform may have several, and they are what
		`kui.build.Payload` is keyed by.
	**/
	var toolchains:Array<String>;

	/** For messages only, so an error can say who chose the platform. **/
	var backend:String;
};

class Host {
	#if macro
	static var declared:Null<Declaration> = null;

	/** Called by a backend's own init macro. See the class documentation. **/
	public static function register(declaration:Declaration):Void
		declared = declaration;

	/**
		The platform this build targets, or `null` if nobody said.

		An explicit `-D kui_platform` wins over a registration, because a build
		file is the more specific statement and because Qt needs it.
	**/
	public static function platform():Null<String> {
		var defined = Context.definedValue("kui_platform");
		if (defined != null) return defined;
		return declared == null ? null : declared.platform;
	}

	/** The link steps a payload may have to reach. **/
	public static function toolchains():Array<String> {
		var defined = Context.definedValue("kui_toolchains");
		if (defined != null) return defined.split(",");
		return declared == null ? [] : declared.toolchains;
	}

	/** Who registered, for a message that names them. **/
	public static function backend():Null<String>
		return declared == null ? null : declared.backend;
	#end
}
