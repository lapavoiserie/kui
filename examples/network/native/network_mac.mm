// macOS, through SystemConfiguration.
//
// `SCNetworkReachabilityGetFlags` is a synchronous question with a synchronous
// answer, which is the only shape this capability wants: the asynchronous
// sibling, `SCNetworkReachabilitySetCallback`, delivers on a run loop and would
// call into Haxe from a thread hxcpp was never told about.
//
// The address is all zeroes on purpose. Reachability for a specific host asks
// the resolver and can block; the zero address asks the far cheaper question
// this capability actually means — is there a route out of here at all.

#include <SystemConfiguration/SystemConfiguration.h>
#include <netinet/in.h>
#include <string.h>

extern "C" bool kui_network_online() {
	struct sockaddr_in zero;
	memset(&zero, 0, sizeof(zero));
	zero.sin_len = sizeof(zero);
	zero.sin_family = AF_INET;

	SCNetworkReachabilityRef target =
		SCNetworkReachabilityCreateWithAddress(NULL, (const struct sockaddr *)&zero);
	if (!target) return false;

	SCNetworkReachabilityFlags flags = 0;
	bool asked = SCNetworkReachabilityGetFlags(target, &flags);
	CFRelease(target);
	if (!asked) return false;

	// Reachable is not enough on its own: a link that would need to be brought
	// up first reports reachable, and answering true there would tell an
	// application it can talk when it cannot.
	bool reachable = (flags & kSCNetworkReachabilityFlagsReachable) != 0;
	bool needsConnection = (flags & kSCNetworkReachabilityFlagsConnectionRequired) != 0;
	return reachable && !needsConnection;
}
