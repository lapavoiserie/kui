# Platforms

A capability is keyed by the **operating system**, and the list is closed:

```
macos  ios  visionos  android  windows  linux  sailfish  browser
```

`kui` may hold that list where `mui` may not hold a list of backends: a backend
is a product anyone may release, an operating system is a fact of the world. It
earns its place by catching the one failure resolution-by-name cannot —
`platform.macOS` and `platform.macos` both look fine to the compiler, and
neither would ever be selected. `-D kui_platform_unchecked` is the escape, and
it is deliberately awkward.

## How kui learns which one

By **registration**, from the backend's own build file:

```
--macro pui.kui.Platform.registerWithKui()
```

Not by resolution. A macro cannot call a function it was only handed the name
of, which is why `mui.macros.Backend.register` has the same shape. And mapping a
build to a platform is knowledge only the backend holds, in its own terms: `sui`
covers macOS, iOS and visionOS off three of its own defines; `cui` runs wherever
it was compiled; `pui` reads `-D pui_surface`. A `#if` ladder for all of that
inside `kui` would be exactly what `mui` spent a day deleting.

## What each backend declares

| Backend | Platform | Toolchains | Why |
|---|---|---|---|
| `pui` | from `-D pui_surface` | varies, below | seven surfaces, four link stories |
| `sui` | `macos` / `ios` / `visionos` | `hxcpp`, `xcode` | hxcpp compiles, Xcode links |
| `aui` | `android` | `gradle` | Haxe targets the JVM; Gradle does everything |
| `wui` | `windows` | `hxcpp`, `msbuild` | hxcpp compiles to a `.lib`, MSBuild links |
| `cui` | where it was built | `hxcpp` | hxcpp does both |
| `qui` | `sailfish` | `qmake` | `-D no-compilation`; qmake does everything |

`pui` declares `["hxcpp"]` on macOS and Windows, `["hxcpp", "xcode"]` on iOS,
`["hxcpp", "gradle"]` on Android, and `["qmake"]` on Qt.

Two rows are worth reading twice. **`aui` and `pui` both reach Android** and
declare different toolchains, because `aui` compiles Haxe to a JAR while `pui`
goes through hxcpp and the NDK. **`wui` and `pui` both reach Windows** and
differ the same way. That is the whole reason a payload is keyed by toolchain.

## Qt is the one that must be told

`-D pui_surface=qt` covers desktop Linux **and** SailfishOS, and nothing in Haxe
separates them: `build-pui-sailfish.hxml` and `build-pui-linux.hxml` are
identical, and only `DEFINES += PUI_SAILFISH` in the `.pro` tells them apart —
the C++ preprocessor, long after macros have run.

They are not the same platform. Silica, Maliit, Sailjail and Harbour's list of
allowed libraries exist on one side only. So the Qt branch registers the
toolchain but takes the platform from the build file:

```
-D kui_platform=sailfish
```

An explicit `-D kui_platform` always wins over a registration, because a build
file is the more specific statement. Without it on Qt, nothing is registered and
the first `Kui.get` says so — a guess here would be a guess that compiles.

## Absence is not approval

A build where nobody registered and nothing was defined gets no default:

```
kui does not know which platform this build targets.
  A backend states it — add "--macro <backend>.kui.Platform.registerWithKui()"
  to your build file — or set -D kui_platform=<id>.
  Known: macos, ios, visionos, android, windows, linux, sailfish, browser
```

The same rule `mui.macros.Backend.hasVocabulary()` follows, for the same reason
a schema that accepts everything is a schema that checks nothing.
