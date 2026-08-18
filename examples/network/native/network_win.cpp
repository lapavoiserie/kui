// Windows, through WinINet.
//
// `InternetGetConnectedState` answers the one question this capability asks,
// synchronously, with no COM and no callback. The richer answer would be
// `INetworkListManager`, which wants COM initialised on the calling thread --
// state a capability has no business imposing on its host.

#include <windows.h>
#include <wininet.h>

extern "C" bool kui_network_online() {
	DWORD flags = 0;
	return InternetGetConnectedState(&flags, 0) != FALSE;
}
