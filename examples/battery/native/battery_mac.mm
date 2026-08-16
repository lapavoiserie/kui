// The battery, on macOS, through IOKit.
//
// Nothing here knows about pui, cui, or any other backend — it talks to the
// operating system, which is the whole argument for keying a capability by
// platform. The same file serves every backend that builds for macOS.

#include <IOKit/ps/IOPowerSources.h>
#include <IOKit/ps/IOPSKeys.h>
#include <CoreFoundation/CoreFoundation.h>

extern "C" {

/** Charge remaining, or -1 on a machine with no battery — a desktop Mac. **/
int kui_battery_level() {
	int percent = -1;
	CFTypeRef blob = IOPSCopyPowerSourcesInfo();
	if (!blob) return percent;
	CFArrayRef sources = IOPSCopyPowerSourcesList(blob);
	if (sources) {
		for (CFIndex i = 0; i < CFArrayGetCount(sources); i++) {
			CFDictionaryRef source = IOPSGetPowerSourceDescription(blob,
				CFArrayGetValueAtIndex(sources, i));
			if (!source) continue;
			CFNumberRef current = (CFNumberRef)CFDictionaryGetValue(source,
				CFSTR(kIOPSCurrentCapacityKey));
			CFNumberRef maximum = (CFNumberRef)CFDictionaryGetValue(source,
				CFSTR(kIOPSMaxCapacityKey));
			int now = 0, full = 0;
			if (current && maximum
				&& CFNumberGetValue(current, kCFNumberIntType, &now)
				&& CFNumberGetValue(maximum, kCFNumberIntType, &full) && full > 0) {
				percent = (int)((now * 100.0) / full + 0.5);
				break;
			}
		}
		CFRelease(sources);
	}
	CFRelease(blob);
	return percent;
}

/**
	Whether the machine is drawing from the mains.

	A different question from `kui_battery_charging`, and asked of a different
	API on purpose. `kIOPSIsChargingKey` is false on a laptop plugged in at
	100 % — the battery is charged, not charging — so reading it as "plugged in"
	tells the user they are on battery while the charger sits in the wall.

	`IOPSGetProvidingPowerSourceType` answers the question actually being asked,
	and answers it correctly on a desktop Mac too: no battery, always AC.
**/
bool kui_battery_powered() {
	CFTypeRef blob = IOPSCopyPowerSourcesInfo();
	if (!blob) return false;
	// Not copied: IOPSGetProvidingPowerSourceType returns a string owned by the
	// blob, so it must not be released and must not outlive it.
	CFStringRef providing = IOPSGetProvidingPowerSourceType(blob);
	bool powered = providing != NULL
		&& CFStringCompare(providing, CFSTR(kIOPSACPowerValue), 0) == kCFCompareEqualTo;
	CFRelease(blob);
	return powered;
}

bool kui_battery_charging() {
	bool charging = false;
	CFTypeRef blob = IOPSCopyPowerSourcesInfo();
	if (!blob) return charging;
	CFArrayRef sources = IOPSCopyPowerSourcesList(blob);
	if (sources) {
		for (CFIndex i = 0; i < CFArrayGetCount(sources); i++) {
			CFDictionaryRef source = IOPSGetPowerSourceDescription(blob,
				CFArrayGetValueAtIndex(sources, i));
			if (!source) continue;
			CFBooleanRef state = (CFBooleanRef)CFDictionaryGetValue(source,
				CFSTR(kIOPSIsChargingKey));
			if (state) { charging = CFBooleanGetValue(state); break; }
		}
		CFRelease(sources);
	}
	CFRelease(blob);
	return charging;
}

}
