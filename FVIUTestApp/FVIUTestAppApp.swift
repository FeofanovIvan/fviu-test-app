import SwiftUI

@main
@MainActor
struct FVIUTestAppApp: App {
    @StateObject private var container: AppContainer

    init() {
        _container = StateObject(wrappedValue: AppContainer.live())
    }

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(container)
                .environmentObject(container.appState)
                .task {
                    await container.bootstrap()
                }
        }
    }
}
