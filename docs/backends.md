# For backend authors

A backend has two jobs, and the first is one line.

## 1. Say what you are building

```haxe
package mybackend.kui;

class Platform {
	public static function registerWithKui():Void {
		#if macro
		kui.macros.Host.register({
			platform: "windows",
			toolchains: ["hxcpp", "msbuild"],
			backend: "mybackend",
		});
		#end
	}
}
```

and call it from the backend's own `init.hxml`:

```
--macro mybackend.kui.Platform.registerWithKui()
```

`toolchains` is the list of link steps this build actually has. Getting it right
matters: a capability declaring an `hxcpp` payload for a build where hxcpp only
*generates* has said something to a step that never runs.

### Read defines, never `#if`

```haxe
// Wrong. Evaluated in the macro context, where the target's defines do not
// exist — every branch false, nothing registered, and code that looks right.
#if cpp ... #end

// Right.
haxe.macro.Context.definedValue("mybackend_surface")
```

This one costs an afternoon if you meet it the hard way.

## 2. Carry the payload to your link step

Only if your link step is not hxcpp. If hxcpp performs the link, `@:buildXml`
already reaches it and there is nothing to do.

Otherwise read the payload and render it into whatever you generate:

```haxe
var payload = kui.macros.Emit.current();          // in-compilation generators
for (framework in payload.strings("xcode", "frameworks")) ...
```

```haxe
var payload = kui.build.Sidecar.read("build/sui"); // a separate process
```

**Which of the two matters.** If your generator hooks
`Context.onAfterGenerate`, so does `kui`'s sidecar writer — and yours was
registered first, from your `--macro` line, before any capability had been
built. It would read a file that does not exist yet. Use `Emit.current()` there;
use `Sidecar.read` from a CLI or a script that runs afterwards.

Both return the same reader:

| | |
|---|---|
| `strings(toolchain, field)` | every value, deduplicated, in declaration order |
| `objects(toolchain, field)` | for fields whose entries are objects — a NuGet id, an SPM coordinate |
| `sections(toolchain)` | one section per capability, with the declarer's name |
| `names()` | who declared, for a message that can say so |
| `any()` | whether anything did |

`sections` is the one to reach for when two capabilities' contributions must be
kept apart — `kui.build.Qmake` uses it to give each declarer a directory of its
own.

## Add nothing conditionally

A build with no capabilities writes no sidecar, and every reader answers empty
rather than failing. So add your hook unconditionally: a project that uses none
of this must be unaffected, and that is what makes it true rather than merely
intended.

## Worked examples

Four, each a different shape, and all short:

- `sui/tools/cli/Build.hx` — a separate process, merging into a generated
  `project.yml`
- `aui/src/aui/macros/GradleProject.hx` — in-compilation, `sourceSets` and
  `dependencies`
- `wui/src/wui/macros/ProjectGenerator.hx` — in-compilation, `.vcxproj` and
  NuGet
- `kui/src/kui/build/Qmake.hx` — a rendering plus a copy, for a consumer that
  cannot read JSON and does not run on this machine
