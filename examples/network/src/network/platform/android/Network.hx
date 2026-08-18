package network.platform.android;

/**
	Android, through the JVM's own `java.net.NetworkInterface`.

	The one implementation in this capability with **no native payload at all**
	— no Kotlin, no permission, no `@:kuiNative`. `aui` compiles Haxe to a JVM
	jar, and the JVM already knows the network interfaces; asking it is plain
	Haxe. This is the case the `kui` documentation calls legitimate rather than
	an oversight: a capability's platform half may simply be code.

	Deliberately not `ConnectivityManager`, which would answer more precisely
	(metered, validated, …) but needs a `Context` — and a capability is handed
	none. The same boundary that put the battery example on sysfs.
**/
class Network implements network.Network {
	public function new() {}

	public function online():Bool {
		return try {
			var found = false;
			var interfaces = java.net.NetworkInterface.getNetworkInterfaces();
			while (!found && interfaces.hasMoreElements()) {
				var ni = interfaces.nextElement();
				if (ni.isUp() && !ni.isLoopback()) found = true;
			}
			found;
		} catch (e:Dynamic) false;
	}
}
