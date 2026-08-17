package network;

/**
	Whether this machine can reach the network.

	## One synchronous read, and no callback

	The obvious shape for "tell me when connectivity changes" is a native
	callback: `SCNetworkReachabilitySetCallback` on macOS, a netlink socket on
	Linux. This declaration deliberately has neither.

	A callback from the system arrives on a **thread the system chose**, and
	calling into Haxe from there means calling into hxcpp's GC from a thread it
	has not been told about. That is a class of crash this ecosystem has already
	paid for once, and the fix is always the same: let the native side record
	something, and let Haxe come and ask.

	So the capability answers one question, synchronously, with no state and no
	threads — and `network.Watch` builds the watching part in Haxe, where it is
	portable and where stopping it is something an application can actually do.

	That is also what makes this the capability worth writing after `battery`:
	its answer **changes while the application runs**, so an application has to
	own something that must later be stopped. See `rui.Signal.Effect.onCleanup`.
**/
interface Network extends kui.Capability {
	/** Whether the network is reachable right now. **/
	function online():Bool;
}
