import Foundation

enum StoreCategory: String, CaseIterable, Identifiable {
    case all = "الكل", chicken = "فراخ", duck = "بط", turkey = "رومي"
    case pigeonQuail = "حمام وسمان", marinated = "متبلات", cuts = "أجزاء دواجن", other = "أخرى وأرانب"
    var id: String { rawValue }
    var firestoreValue: String {
        switch self {
        case .all: return "ALL"; case .chicken: return "CHICKEN"; case .duck: return "DUCK"
        case .turkey: return "TURKEY"; case .pigeonQuail: return "PIGEON_QUAIL"
        case .marinated: return "MARINATED"; case .cuts: return "CUTS"; case .other: return "OTHER"
        }
    }
}

struct StoreProduct: Identifiable, Hashable {
    var id: String
    var name: String
    var category: StoreCategory
    var subtitle: String
    var price: Double?
    var originalPrice: Double?
    var imageName: String
    var imageURL: URL?
    var badge: String?
    var isAvailable: Bool
    var isOffer: Bool
    var sizes: [String]
    var units: [String]
    var prepOptions: [String]
    var allowHalfUnit: Bool

    var displayPrice: String {
        guard let price else { return "اتصل لمعرفة السعر" }
        return String(format: "%.0f ج.م", price)
    }

    static func from(id: String, data: [String: Any]) -> StoreProduct {
        let cat = StoreCategory.allCases.first { $0.firestoreValue == (data["category"] as? String ?? "CHICKEN") } ?? .chicken
        let prep = (data["prepOptions"] as? [[String: Any]] ?? []).compactMap { $0["type"] as? String }
        let imageName = data["imageResName"] as? String ?? "prod_chicken_whole"
        return StoreProduct(id: id, name: data["name"] as? String ?? "", category: cat,
            subtitle: data["subtitle"] as? String ?? "", price: (data["price"] as? NSNumber)?.doubleValue,
            originalPrice: (data["originalPrice"] as? NSNumber)?.doubleValue, imageName: imageName,
            imageURL: URL(string: data["imageUri"] as? String ?? ""), badge: data["badge"] as? String,
            isAvailable: data["isAvailable"] as? Bool ?? true, isOffer: data["isOffer"] as? Bool ?? false,
            sizes: data["availableSizes"] as? [String] ?? [], units: data["supportedUnits"] as? [String] ?? ["KILO"],
            prepOptions: prep, allowHalfUnit: data["allowHalfUnit"] as? Bool ?? true)
    }
}

struct CartLine: Identifiable, Codable, Hashable {
    var id: UUID = UUID()
    var productID: String
    var name: String
    var price: Double?
    var quantity: Double
    var unit: String
    var size: String = ""
    var prep: String = ""
    var note: String = ""
    var imageName: String = "prod_chicken_whole"
    var total: Double? { price.map { $0 * quantity } }
    var unitLabel: String { ["KILO": "كيلو", "PIECE": "قطعة", "PAIR": "جوز", "PLATE": "طبق", "BIRD": "طائر/دجاجة"][unit] ?? unit }
}

struct StoreBranch: Identifiable {
    let id: String
    let name: String
    let address: String
    let phone: String
    let image: String
    let hours: String = "يومياً: 8:00 ص - 10:00 م"
}

struct StoreOrder: Identifiable {
    var id: String
    var customerName: String
    var customerPhone: String
    var total: Double
    var status: String
    var createdAt: Date
    var summary: String
}

enum StoreBranches {
    static let all = [
        StoreBranch(id: "camp_cesar", name: "فرع كامب شيزار (الرئيسي)", address: "كامب شيزار، الإسكندرية", phone: "01223381405", image: "branch_camp_cesar"),
        StoreBranch(id: "smouha", name: "فرع سموحة", address: "سموحة، الإسكندرية", phone: "01226151455", image: "branch_smouha"),
        StoreBranch(id: "bahary", name: "فرع بحري", address: "بحري، الإسكندرية", phone: "01282398999", image: "branch_bahary")
    ]
}
