package kui.build;

/**
	What an implementation needs the build to do for it.

	Declared once, on the implementation class, as `@:kuiNative({…})`:

	```haxe
	@:kuiNative({
		hxcpp: {files: ["native/battery_mac.mm"], libs: ["-framework", "IOKit"]},
	})
	class Battery implements battery.Battery { … }
	```

	## Keyed by toolchain, not by platform

	Because one platform has several. macOS links through hxcpp under `pui` and
	through Xcode under `sui`; SailfishOS links through qmake under both `qui` and
	`pui`. An implementation states what each link step needs, and only the
	sections for the toolchains actually in the build are read.

	An implementation that declares nothing is pure Haxe — a JVM extern under
	`aui`, the DOM in a browser — and that is a legitimate capability, not an
	oversight.

	## Paths are relative to the library root

	Never to the working directory. That is the one thing `qui`'s `modules/native`
	scan could not do, and the reason an extension had to be physically copied into
	every project that wanted it: a CWD-relative path cannot come from a haxelib.
	`kui` resolves these to absolute at macro time, so what reaches a build script
	needs no further interpretation.

	## Why a typed structure and not a JSON file

	Because it is checked where it is written. `kui.macros.CapabilityMacro` types
	the literal against this typedef before reading it, so a misspelled field is an
	error at the metadata's own position rather than a key silently ignored three
	build steps later.
**/
typedef Payload = {
	?hxcpp:HxcppPayload,
	?qmake:QmakePayload,
	?xcode:XcodePayload,
	?gradle:GradlePayload,
	?msbuild:MsbuildPayload,
};

/** What hxcpp links itself: `cui`, `pui` on macOS and Windows. **/
typedef HxcppPayload = {
	?files:Array<String>,
	?includes:Array<String>,
	?libs:Array<String>,
	?flags:Array<String>,
};

/**
	What qmake needs: SailfishOS and Linux, under `qui` and `pui`.

	This is the section that cannot ride on `@:buildXml`. A `.pro` collects its
	sources by globbing and reads nothing hxcpp writes, so `kui` renders this into
	a `.pri` fragment the `.pro` includes.
**/
typedef QmakePayload = {
	?files:Array<String>,
	?includes:Array<String>,
	?qt:Array<String>,
	?pkgconfig:Array<String>,
	?config:Array<String>,
	?libs:Array<String>,
};

/** What an Xcode project needs: `sui`, and `pui` on iOS. **/
typedef XcodePayload = {
	?sources:Array<String>,
	?frameworks:Array<String>,
	?packages:Array<{url:String, from:String, product:String}>,
};

/** What Gradle needs: `aui`, and `pui` on Android. **/
typedef GradlePayload = {
	?sources:Array<String>,
	?dependencies:Array<String>,
	?permissions:Array<String>,
};

/** What MSBuild needs: `wui`. **/
typedef MsbuildPayload = {
	?sources:Array<String>,
	?includes:Array<String>,
	?libs:Array<String>,
	?nuget:Array<{id:String, version:String}>,
};
