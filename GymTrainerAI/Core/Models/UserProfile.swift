import Foundation

struct UserProfile: Codable {
    var name: String
    var age: Int
    var gender: Gender
    var fitnessLevel: FitnessLevel
    var goals: [Goal]
    var availableDaysPerWeek: Int
    var hasEquipment: EquipmentAccess
    var injuries: [String]

    enum Gender: String, Codable, CaseIterable {
        case male, female, other
    }

    enum FitnessLevel: String, Codable, CaseIterable {
        case beginner, intermediate, advanced
    }

    enum Goal: String, Codable, CaseIterable {
        case muscleGain = "Muscle Gain"
        case fatLoss = "Fat Loss"
        case strength = "Strength"
        case endurance = "Endurance"
        case generalFitness = "General Fitness"
    }

    enum EquipmentAccess: String, Codable, CaseIterable {
        case fullGym = "Full Gym"
        case dumbbellsOnly = "Dumbbells Only"
        case barbellAndRack = "Barbell & Rack"
        case bodyweightOnly = "Bodyweight Only"
    }

    static var empty: UserProfile {
        UserProfile(
            name: "",
            age: 25,
            gender: .male,
            fitnessLevel: .beginner,
            goals: [.muscleGain],
            availableDaysPerWeek: 4,
            hasEquipment: .fullGym,
            injuries: []
        )
    }
}
