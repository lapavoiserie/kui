import SwiftUI

@main
struct BatteryAppApp: App {
    init() {
        HaxeRuntime.initialize()
    }


    var body: some Scene {
        WindowGroup("BatteryApp") {
            ContentView()
        }
    }
}
