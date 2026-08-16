# Native payloads

Declaring the API is the easy half. **Getting the native code to the linker is
the work**, because this ecosystem has five link steps and only one of them is
hxcpp.

## One declaration, keyed by toolchain

```haxe
@:kuiNative({
	hxcpp:   {files: [...], includes: [...], libs: [...], flags: [...]},
	qmake:   {files: [...], includes: [...], qt: [...], pkgconfig: [...], config: [...], libs: [...]},
	xcode:   {sources: [...], frameworks: [...], packages: [...]},
	gradle:  {sources: [...], dependencies: [...], permissions: [...]},
	msbuild: {sources: [...], includes: [...], libs: [...], nuget: [...]},
})
```

**Keyed by toolchain rather than by platform**, because one operating system has
several. macOS links through hxcpp under `pui` and `cui`, and through Xcode
under `sui`. Windows compiles through hxcpp and links through MSBuild. So an
implementation may have to say the same thing twice, in two dialects — and the
example capability does exactly that:

```haxe
hxcpp: {files: ["native/battery_mac.mm"], libs: ["-framework", "IOKit"]},
xcode: {frameworks: ["IOKit"]},
```

The literal is **type-checked** against `kui.build.Payload` before it is read, so
a misspelled field is an error at the metadata's own position rather than a key
quietly ignored three build steps later.

## Paths are relative to the library root

Never to the working directory. That is the one thing `qui`'s `modules/native`
scan could not do, and the reason an extension had to be physically copied into
every project that wanted it: a working-directory-relative path cannot come from
a haxelib. `kui` walks up from the implementation's own source file to the
directory holding `haxelib.json` and resolves everything against that, at macro
time.

Only `files`, `includes` and `sources` are treated as paths. `IOKit`,
`androidx.annotation:annotation:1.9.1` and `PowrProf.lib` are tokens the build
system resolves itself — resolving those would turn `IOKit` into a directory
that does not exist.

## Two channels reach five link steps

### `@:buildXml`, where hxcpp links

`kui` synthesises the `hxcpp` section into `@:buildXml` on the implementation
class. That reaches the generated `Build.xml` whole, survives `-dce full` and
survives the indirect shape `Kui.get` emits — established by the probe in
`probes/buildxml-through-macro` rather than assumed.

Each capability gets a **file group of its own**, never `<files id="haxe">`.
Two reasons, and the first is not a matter of taste: hxcpp's own group carries a
precompiled header, and under MSVC every file in such a group must include it —
a capability's C++ has no reason to include `hxcpp.h`, and the failure names the
capability's file while explaining nothing. And a `compilerflag` in that group
applies to *every* generated Haxe source, so one capability's `-I` would reach
all of them.

### The resolved sidecar, where it does not

The other four link steps never open `Build.xml`, and could not use it if they
did: `${haxelib:x}` is expanded only by hxcpp's own build tool. So `kui` writes
`kui-payload.json` beside the generated output — the same payloads, every path
already absolute — and each consumer reads what concerns it.

| Toolchain | Who reads it | How |
|---|---|---|
| `xcode` | `sui/tools/cli/Build.hx` | merges into the generated `project.yml`, copies Swift |
| `gradle` | `aui/src/aui/macros/GradleProject.hx` | `sourceSets`, `dependencies`, `<uses-permission>` |
| `msbuild` | `wui/src/wui/macros/ProjectGenerator.hx` | `ClCompile`, `AdditionalDependencies`, NuGet imports |
| `qmake` | both `.pro` files | `include(kui-native.pri)` |

A generator that runs **inside the compilation** — `aui`'s and `wui`'s both hook
`Context.onAfterGenerate`, and register before any capability has been built —
must not read the file, because it does not exist yet. Those call
`kui.macros.Emit.current()` and get the same reader over the payloads still in
memory. A separate process — `sui`'s CLI, a `.pro`, a shell script — reads the
file.

## qmake is the one that also copies

A `.pro` has no JSON parser, and both of the ones in play collect their sources
by scanning rather than from a list anyone can append to. So the qmake section
is rendered into `kui-native.pri`, which the `.pro` includes under an `exists()`
guard.

And its sources are **copied**, not merely named — the one place where an
absolute path is the wrong answer. Both Qt builds compile inside a container:
`qui` tars its tree and runs `buildrpm` in the Sailfish SDK image, and `pui`'s
Sailfish packaging does the same. An absolute host path would be written
correctly and be missing at the only moment it is read, and a capability from a
haxelib lives outside the tarball whatever its path says. Copied to
`kui-native/<capability>/` and named with `$$PWD`, it travels.

One directory per capability, so two may each ship a `native/util.cpp` without
one overwriting the other.

## The package name the compiler had already taken

`kui` keys capabilities by operating system, and one of those ids is `linux`.
GCC and clang define `linux` — and `unix`, and `i386` — as `1` outside strict
ISO mode, and Haxe turns a package into a C++ namespace verbatim. So an
implementation at `battery.platform.linux.Battery` generates

```cpp
namespace battery{ namespace platform{ namespace linux{
```

which the preprocessor rewrites to `namespace 1{` before the compiler sees it.
The error is `expected identifier before numeric constant`, at an ordinary-looking
line, in a file nobody wrote.

This is **`kui`'s** problem rather than the author's: `kui` chose the id, and the
`p.platform.<id>.Name` convention follows from it. So `kui` emits `-Ulinux`
itself, for the **whole program** — the namespace is named by every generated
source that reaches the capability, not just by the capability's own file — and
it emits it twice, because hxcpp reads the metadata and qmake reads the `.pri`
and neither reads the other.

It is emitted for an implementation with **no native payload at all**, which is
the case that makes this a rule rather than a footnote: a pure-Haxe Linux
capability breaks the build just as thoroughly.

Undefining is what strict ISO mode does anyway; portable code tests `__linux__`,
which is untouched.

## A build with no capabilities

Writes no sidecar, no `.pri`, and changes nothing. Every consumer adds its hook
unconditionally and finds nothing — which is why using none of this costs
nothing.
