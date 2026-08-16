# Limits

Stated here rather than left to be discovered.

## No native views

A camera preview or a map *inside the view tree* is a strictly harder problem
than a capability, and it is not what `kui` does.

Three backends render through a closed vocabulary with a macro-time coverage
check — `sui` parses the `switch` in `DynamicView.swift`, `aui` the `when` in
`DynamicComposable.kt` — and `pui` would have to decide what it *draws* in place
of a view it cannot host. That is a separate design.

What this one preserves for it: capabilities are keyed by platform and resolved
by name, so a view extension can reuse both mechanisms.

## No window handle

A capability is handed nothing but itself. A share sheet needs a
`UIViewController`, an Android file picker needs an `Activity`, a Qt dialog
wants a parent widget — and the moment one of those is required, "a capability
depends on no backend" stops being true.

The example capability shows the cost honestly: its Android half reads sysfs
rather than `BatteryManager`, because `BatteryManager` needs a `Context`.

**This is the design's real boundary.** If the first capabilities anyone
actually asks for all need a window handle, then keying by platform alone is the
wrong call and should be reconsidered before more is built on it — not patched
around.

## No sandbox, and no dependency policing

A capability is arbitrary native code compiled into the process, with the same
trust boundary any native dependency carries. `kui` does not inspect it, does
not restrict what it links, and does not check what it pulls in. That is a
decision, not an omission.

## No runtime discovery

The roster comes from `@:autoBuild`, which fires only for classes the compiler
actually builds. An implementation nothing references may never register. In
practice `Kui.get` is what references it, so a capability an application uses is
a capability the compiler builds — but a backend wanting the full roster for its
own purposes (`qui`'s CPPIA force-references) sees only what was reached.

## One instance per implementation

`Kui.instance` caches, because a capability usually wraps something the platform
has exactly one of. A capability needing several instances does not fit, and
should expose a factory method rather than being constructed twice.

## Reflection in the constructor path

`Type.createInstance` looks like an obvious thing to replace with a direct
`new`. It is what makes an interpreted CPPIA guest route to the host's compiled
class under `qui`, and it should not be changed without measuring on a Sailfish
device first.

## What is verified, and what is not

The four non-hxcpp link channels each carry a real capability, and three of the
four have been run:

| Channel | Built | What it answered |
|---|---|---|
| hxcpp | macOS | `pui`, `cui` — `level 100, plugged in, not charging` |
| Xcode | macOS | `sui` — the same, through IOKit |
| Xcode | iOS | `sui` on a simulator — `level -1, power source unknown` |
| Gradle | Android | an emulator, denied sysfs — `level -1, power source unknown` |
| MSBuild | Windows | a desktop, `PowrProf.lib` linked — `level -1, on mains power` |
| qmake | SailfishOS, aarch64 | compiled and linked; **not yet run on a device** |

Only macOS was in a position to return a charge figure, and it returned the
right one — `pmset` agrees on all three of level, mains and not-charging. Each
`-1` is the contract's "no reading here", confirmed independently: `wmic`
reports no battery on the Windows machine, `adb shell` is refused the same sysfs
node the app is, and an iOS simulator is not given a battery. What those runs
prove is that the native code was linked, found and called.

Note what the Windows and iOS rows do **not** say. A desktop knows it is on
mains; a simulator knows nothing, and says so. Collapsing the two would have
been easy and would have been a guess.

The qmake channel is compiled and linked by the Sailfish SDK container, which is
the step that proves the `.pri` reaches qmake. Running it on the phone is
pending and is the one claim not to make until it has happened.
