// Linux and SailfishOS, through sysfs.
//
// No Qt, no D-Bus, no UPower: the kernel exposes the battery as two files, and
// reading them needs nothing linked. That makes this the one implementation in
// the example whose payload names **no library at all** — only a source file —
// which is worth having, because "a capability that needs nothing linked" is
// the common case and the build has to handle it as gracefully as the others.
//
// It reaches qmake through `kui-native.pri`, not through `@:buildXml`: on Qt,
// hxcpp only generates C++, and the `.pro` compiles and links everything.

#include <cstdio>
#include <cstring>

namespace {

// SailfishOS and most Linux laptops disagree about the node's name, so both are
// tried. A laptop has BAT0 or BAT1; a phone has "battery".
const char *const SUPPLIES[] = {
	"/sys/class/power_supply/battery",
	"/sys/class/power_supply/BAT0",
	"/sys/class/power_supply/BAT1",
};

bool read_file(const char *path, char *out, size_t size) {
	FILE *f = fopen(path, "r");
	if (!f) return false;
	bool ok = fgets(out, (int)size, f) != nullptr;
	fclose(f);
	return ok;
}

bool read_attribute(const char *name, char *out, size_t size) {
	for (const char *supply : SUPPLIES) {
		char path[256];
		snprintf(path, sizeof(path), "%s/%s", supply, name);
		if (read_file(path, out, size)) return true;
	}
	return false;
}

} // namespace

extern "C" int kui_battery_level() {
	char value[32];
	if (!read_attribute("capacity", value, sizeof(value))) return -1;
	int level = -1;
	if (sscanf(value, "%d", &level) != 1) return -1;
	return level;
}

extern "C" bool kui_battery_charging() {
	char value[32];
	if (!read_attribute("status", value, sizeof(value))) return false;
	return strncmp(value, "Charging", 8) == 0;
}
