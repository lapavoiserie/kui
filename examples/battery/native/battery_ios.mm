// iOS, through UIKit.
//
// Not IOKit, which is what the macOS half uses: the power-source API it calls
// is not public on iOS. UIKit answers the same two questions through
// `UIDevice`, and that is the whole difference between the two files — the same
// capability, a different way of asking, which is precisely what a per-platform
// implementation is for.
//
// **Monitoring has to be turned on first.** `batteryLevel` answers -1.0 until
// `batteryMonitoringEnabled` is set, and that is the one thing about this API
// that reads as a broken device rather than a missing call. It is enabled once,
// lazily, rather than in some initialiser: a capability is constructed the
// first time it is reached and may never be reached at all.
//
// Written for manual reference counting. hxcpp compiles Objective-C++ without
// ARC, so nothing here may rely on it — `currentDevice` returns a shared
// instance this file does not own, which is why there is no retain and no
// release.

#import <UIKit/UIKit.h>

namespace {

UIDevice *monitored_device() {
	UIDevice *device = [UIDevice currentDevice];
	if (!device.batteryMonitoringEnabled) device.batteryMonitoringEnabled = YES;
	return device;
}

} // namespace

extern "C" int kui_battery_level() {
	float level = monitored_device().batteryLevel;
	// -1.0 means "unknown", which the simulator reports for a while after the
	// first call and a device reports when monitoring has just been enabled.
	// The capability's contract says -1 for "no reading", so it passes through.
	if (level < 0.0f) return -1;
	return (int)(level * 100.0f + 0.5f);
}

// Plugged in, whether or not the battery is still filling. "Full" is the state
// that makes the distinction matter: a device on the charger at 100 % reports
// Full, not Charging, and reading Charging as "plugged in" would tell its owner
// they are on battery with the cable attached.
extern "C" bool kui_battery_powered() {
	UIDeviceBatteryState state = monitored_device().batteryState;
	return state == UIDeviceBatteryStateCharging || state == UIDeviceBatteryStateFull;
}

extern "C" bool kui_battery_charging() {
	UIDeviceBatteryState state = monitored_device().batteryState;
	// "Full" is not "charging": a device on the charger at 100% has stopped.
	return state == UIDeviceBatteryStateCharging;
}
