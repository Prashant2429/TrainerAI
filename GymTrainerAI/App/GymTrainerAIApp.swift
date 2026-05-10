import SwiftUI
import SwiftData

@main
struct GymTrainerAIApp: App {

    @StateObject private var sessionManager = SessionManager()

    init() {
        NotificationService.shared.requestPermission()
    }

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(sessionManager)
        }
        .modelContainer(
            for: [
                SetLogEntry.self,
                WorkoutRecord.self,
                WorkoutPlan.self,
                PlannedDay.self,
                PlannedExercise.self
            ]
        )
    }
}

struct RootView: View {

    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject var sessionManager: SessionManager

    var body: some View {
        ContentView()
            .onAppear {
                sessionManager.modelContext = modelContext
            }
    }
}
