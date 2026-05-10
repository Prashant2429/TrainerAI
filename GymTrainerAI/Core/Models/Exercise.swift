import Foundation

struct Exercise: Codable, Identifiable {
    let id: String
    let name: String
    let musclesTargeted: [String]
    let category: Category
    let cameraAngle: CameraAngle
    let phonePlacementInstruction: String
    let formRules: [FormRule]
    let stepByStepCues: [String]
    let commonMistakes: [String]

    enum Category: String, Codable {
        case compound, isolation, shoulder, cable, cardio
    }

    enum CameraAngle: String, Codable {
        case sideProfile = "Side profile"
        case frontFacing = "Front facing"
        case diagonal45 = "45° diagonal"
    }
}

struct FormRule: Codable, Identifiable {
    let id: String
    let description: String
    let jointKeypoints: [String]       // e.g. ["leftKnee", "leftHip", "leftAnkle"]
    let errorCondition: String         // e.g. "kneeAngle < 85"
    let severity: Severity
    let midRepCue: String              // short: "knees out"
    let debriefCue: String             // full sentence for between-set debrief

    enum Severity: String, Codable {
        case warning   // cue after 2+ reps
        case critical  // cue immediately
    }
}
