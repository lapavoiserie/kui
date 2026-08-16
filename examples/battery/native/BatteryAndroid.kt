package kui.example

import androidx.annotation.Keep
import java.io.File

/**
 * The Android half of the `battery` capability.
 *
 * Read from sysfs rather than through `BatteryManager`, and that is a deliberate
 * limitation rather than an oversight: `BatteryManager` needs a `Context`, and a
 * `kui` capability is handed none. Reaching the host's `Application` would make
 * "a capability depends on no backend" false, which is the design's stated
 * boundary — so this one stays inside what a plain JVM object can do, and a real
 * capability that needs a `Context` is what will decide whether that boundary
 * moves.
 *
 * `@Keep` earns its place twice over: the methods are reached only by name, from
 * Haxe, so R8 in a release build has no reference to follow — and it makes this
 * file genuinely need the `androidx.annotation` dependency the capability
 * declares, rather than declaring one for show.
 */
@Keep
object BatteryNative {
    private const val SYSFS = "/sys/class/power_supply/battery"

    @JvmStatic
    @Keep
    fun level(): Int = read("capacity")?.toIntOrNull() ?: -1

    @JvmStatic
    @Keep
    fun charging(): Boolean = read("status")?.equals("Charging", ignoreCase = true) ?: false

    private fun read(name: String): String? = try {
        File("$SYSFS/$name").readText().trim()
    } catch (e: Exception) {
        // No battery node at all — a device without one, or an emulator image
        // that does not expose it. Answered as "unknown" rather than thrown,
        // because the capability's contract says -1 for "no battery here".
        null
    }
}
