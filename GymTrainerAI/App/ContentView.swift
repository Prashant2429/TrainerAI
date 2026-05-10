import SwiftUI

struct ContentView: View {
    @StateObject private var sessionManager = SessionManager()
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false
    @Environment(\.modelContext) private var modelContext

    var body: some View {
        Group {
            if !hasCompletedOnboarding {
                OnboardingView()
            } else {
                TabView {
                    HomeView()
                        .tabItem {
                            Label("Home", systemImage: "house.fill")
                        }
                    FingerTestView()
                        .tabItem {
                            Label("Test", systemImage: "hand.raised.fill")
                        }
                }
                .tint(Color(red: 0.78, green: 1.00, blue: 0.18)) // DS.lime
            }
        }
        .environmentObject(sessionManager)
        .onAppear { sessionManager.modelContext = modelContext }
    }
}
