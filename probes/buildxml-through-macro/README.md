# Does `@:buildXml` added by a macro reach hxcpp?

The one question the whole hxcpp channel depends on. `kui` asks an author to
declare a native payload once, as `@:kuiNative`, and synthesises the hxcpp
fragment from it — which means adding metadata **from inside a build macro**,
after the class has been read. If the generator has already made up its mind by
then, the design needs a fallback where the author writes both notations by hand
and `kui` only checks they agree.

## The answer: yes, on all four counts

Run from this directory:

```
haxe -cp . -main Spike2 -cpp out -D no-compilation -D kui_platform=macos -dce full
```

**1. The fragment reaches `Build.xml`, whole and in the right place** — after the
`BuildCommon.xml` include, with the `<compilerflag>`, the `<file>` and the
`<target><lib>` pair intact:

```xml
<files id="haxe"><file name="/spike/native/battery_mac.mm" /></files><target id="haxe"><lib name="-framework" /><lib name="IOKit" /></target>
```

**2. It survives the shape `kui` actually produces.** The implementation class is
never named by the application: `Kui.get(battery.Battery)` resolves
`battery.platform.macos.Battery` and emits
`(kui.Kui.instance(battery.platform.macos.Battery) : battery.Battery)`. The class
is reached only through that emitted expression and instantiated reflectively —
and the build macro still fires, because naming a type is what loads it.

**3. It survives `-dce full`**, which was the real worry: a class whose methods
are only ever called through an interface is exactly what dead-code elimination
exists to remove. The `@:keep` the macro stamps alongside is what earns that, and
it is the same `@:keep` `qui.native.NativeModuleMacro` has always stamped.

**4. A missing implementation is a compile error at the call site**, naming the
capability, the platform, and the path that was looked for:

```
Spike2.hx:3: characters 11-39 : battery.Battery has no implementation for "browser" (looked for battery.platform.browser.Battery)
```

And it runs — `haxe -cp . -main Spike2 --interp -D kui_platform=macos` prints
`level 87`, so the macro-emitted `Type.createInstance` plus the interface cast is
sound.

## What this does *not* answer

The fragment reaching `Build.xml` is only useful where **hxcpp performs the
link**. Four link steps in this ecosystem never read that file: qmake globs its
sources, and the iOS and Android scripts hardcode theirs. Worse, a path written
as `${haxelib:x}` is expanded by hxcpp's build tool alone, so a `.pro` that did
read `Build.xml` would find an unresolved variable.

That is why `kui` emits a second, already-resolved artefact for those four. This
probe proves the easy channel, not the hard one — and the hard one is the work.
