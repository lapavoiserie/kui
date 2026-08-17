// Linux, through sysfs.
//
// `/sys/class/net/<iface>/operstate` says "up" for an interface that is
// actually carrying traffic. Reading it needs nothing linked and no daemon —
// the alternative, a netlink socket, would deliver asynchronously and want a
// thread, which is exactly what this capability avoids.
//
// The loopback interface is skipped: `lo` is always up, and a machine that can
// only talk to itself is not online.

#include <cstdio>
#include <cstring>
#include <dirent.h>

extern "C" bool kui_network_online() {
	DIR *dir = opendir("/sys/class/net");
	if (!dir) return false;

	bool online = false;
	struct dirent *entry;
	while (!online && (entry = readdir(dir)) != nullptr) {
		if (entry->d_name[0] == '.') continue;
		if (strcmp(entry->d_name, "lo") == 0) continue;

		char path[512];
		snprintf(path, sizeof(path), "/sys/class/net/%s/operstate", entry->d_name);
		FILE *f = fopen(path, "r");
		if (!f) continue;
		char state[32] = {0};
		if (fgets(state, sizeof(state), f)) online = strncmp(state, "up", 2) == 0;
		fclose(f);
	}
	closedir(dir);
	return online;
}
