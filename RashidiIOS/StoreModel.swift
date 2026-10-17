import Foundation
import Combine
#if canImport(FirebaseCore)
import FirebaseCore
import FirebaseAuth
import FirebaseFirestore
#endif

@MainActor
final class StoreModel: ObservableObject {
    @Published var products: [StoreProduct] = []
    @Published var cart: [CartLine] = []
    @Published var orders: [StoreOrder] = []
    @Published var isFirebaseReady = false
    @Published var notice: String?
    @Published var adminEmail = ""

    #if canImport(FirebaseCore)
    private var db: Firestore?
    private var productsListener: ListenerRegistration?
    private var ordersListener: ListenerRegistration?
    #endif

    init() {
        loadCart()
        #if canImport(FirebaseCore)
        if Bundle.main.url(forResource: "GoogleService-Info", withExtension: "plist") != nil {
            if FirebaseApp.app() == nil { FirebaseApp.configure() }
            db = Firestore.firestore()
            isFirebaseReady = true
            listenToProducts()
        }
        #endif
        if products.isEmpty { products = Self.previewProducts }
    }

    deinit {
        #if canImport(FirebaseCore)
        productsListener?.remove(); ordersListener?.remove()
        #endif
    }

    var cartCount: Int { cart.reduce(0) { $0 + Int($1.quantity) } }
    var subtotal: Double { cart.compactMap(\.total).reduce(0, +) }

    func add(_ product: StoreProduct, quantity: Double = 1, unit: String = "KILO", size: String = "", prep: String = "", note: String = "") {
        cart.append(CartLine(productID: product.id, name: product.name, price: product.price, quantity: quantity,
                             unit: unit, size: size, prep: prep, note: note, imageName: product.imageName))
        saveCart(); notice = "נוסף לסל"
    }

    func changeQuantity(_ line: CartLine, by amount: Double) {
        guard let index = cart.firstIndex(where: { $0.id == line.id }) else { return }
        cart[index].quantity += amount
        if cart[index].quantity <= 0 { cart.remove(at: index) }
        saveCart()
    }

    func remove(_ line: CartLine) { cart.removeAll { $0.id == line.id }; saveCart() }

    func submitOrder(name: String, phone: String, method: String, address: String, street: String, buildingInfo: String, time: String, payment: String, notes: String) async -> Bool {
        guard !cart.isEmpty else { notice = "السلة فارغة"; return false }
        guard !name.trimmingCharacters(in: .whitespaces).isEmpty, phone.count >= 8 else { notice = "أدخل الاسم ورقم هاتف صحيحاً"; return false }
        guard !address.isEmpty else { notice = method == "توصيل للمنزل" ? "اختر منطقة التوصيل" : "اختر الفرع"; return false }
        if method == "توصيل للمنزل" && street.trimmingCharacters(in: .whitespaces).isEmpty { notice = "أدخل اسم الشارع"; return false }
        let id = String(UUID().uuidString.prefix(8))
        let itemData: [[String: Any]] = cart.map { line in
            let category = products.first(where: { $0.id == line.productID })?.category.firestoreValue ?? "OTHER"
            return ["cartItemId": line.id.uuidString, "productId": line.productID, "productName": line.name,
                "productCategory": category, "price": line.price ?? 0, "quantity": line.quantity, "unit": line.unit,
                "selectedSize": line.size, "selectedPrep": line.prep, "specialNotes": line.note]
        }
        let deliveryCode = method == "توصيل للمنزل" ? "HOME_DELIVERY" : "BRANCH_PICKUP"
        let paymentCode = payment == "Instapay" ? "INSTAPAY" : "CASH"
        let payload: [String: Any] = ["orderId": id, "customerName": name, "customerPhone": phone,
            "deliveryMethod": deliveryCode, "branchName": method == "استلام من الفرع" ? address : "",
            "area": method == "توصيل للمنزل" ? address : "", "street": street, "buildingInfo": buildingInfo,
            "deliveryTimeSlot": time, "paymentMethod": paymentCode,
            "generalNotes": notes, "items": itemData, "subtotal": subtotal, "deliveryFee": 0,
            "total": subtotal, "pointsEarned": 0, "timestamp": "اليوم", "status": "قيد المراجعة والتجهيز", "createdAt": Date().timeIntervalSince1970 * 1000]
        #if canImport(FirebaseFirestore)
        guard let db else { notice = "تعذر الاتصال بقاعدة البيانات. حاول لاحقاً."; return false }
        do {
            try await db.collection("orders").document(id).setData(payload)
            cart.removeAll(); saveCart(); notice = "تم استلام طلبك رقم \(id)"; return true
        } catch {
            notice = "تعذر إرسال الطلب: \(error.localizedDescription)"; return false
        }
        #else
        notice = "أضف إعدادات Firebase الخاصة بتطبيق iOS لإرسال الطلبات."; return false
        #endif
    }

    func signInAdmin(email: String, password: String) async -> Bool {
        #if canImport(FirebaseAuth)
        do {
            let credential = try await Auth.auth().signIn(withEmail: email, password: password)
            guard let db else { notice = "Firebase غير مهيأ"; return false }
            let admin = try await db.collection("admins").document(credential.user.uid).getDocument()
            guard admin.exists else { try? Auth.auth().signOut(); notice = "هذا الحساب غير مخول كمدير"; return false }
            adminEmail = email; listenToOrders(); return true
        } catch { notice = "تعذر تسجيل الدخول: \(error.localizedDescription)"; return false }
        #else
        notice = "أضف إعدادات Firebase iOS أولاً"; return false
        #endif
    }

    func updateStatus(_ order: StoreOrder, status: String) async {
        #if canImport(FirebaseFirestore)
        do { try await db?.collection("orders").document(order.id).updateData(["status": status]) }
        catch { notice = "تعذر تحديث حالة الطلب" }
        #endif
    }

    func signOut() {
        #if canImport(FirebaseAuth)
        try? Auth.auth().signOut()
        #endif
        ordersListener?.remove(); adminEmail = ""
    }

    private func saveCart() {
        if let data = try? JSONEncoder().encode(cart) { UserDefaults.standard.set(data, forKey: "rashidi.cart.v1") }
        objectWillChange.send()
    }
    private func loadCart() {
        guard let data = UserDefaults.standard.data(forKey: "rashidi.cart.v1"), let lines = try? JSONDecoder().decode([CartLine].self, from: data) else { return }
        cart = lines
    }

    #if canImport(FirebaseFirestore)
    private func listenToProducts() {
        productsListener = db?.collection("products").addSnapshotListener { [weak self] snapshot, error in
            guard let self else { return }
            Task { @MainActor in
                if let documents = snapshot?.documents {
                    let live = documents.map { StoreProduct.from(id: $0.documentID, data: $0.data()) }
                    if !live.isEmpty { self.products = live.sorted { $0.name.localizedCompare($1.name) == .orderedAscending } }
                } else if let error { self.notice = "تعذر تحميل المنتجات: \(error.localizedDescription)" }
            }
        }
    }
    private func listenToOrders() {
        ordersListener = db?.collection("orders").order(by: "createdAt", descending: true).addSnapshotListener { [weak self] snapshot, _ in
            guard let self else { return }
            Task { @MainActor in
                self.orders = (snapshot?.documents ?? []).map { doc in
                    let data = doc.data(); let date = Date(timeIntervalSince1970: ((data["createdAt"] as? NSNumber)?.doubleValue ?? 0) / 1000)
                    let items = (data["items"] as? [[String: Any]] ?? []).compactMap { $0["productName"] as? String }.joined(separator: "، ")
                    return StoreOrder(id: doc.documentID, customerName: data["customerName"] as? String ?? "عميل",
                        customerPhone: data["customerPhone"] as? String ?? "", total: (data["total"] as? NSNumber)?.doubleValue ?? 0,
                        status: data["status"] as? String ?? "قيد المراجعة", createdAt: date, summary: items)
                }
            }
        }
    }
    #endif

    static let previewProducts: [StoreProduct] = [
        StoreProduct(id: "chk_white", name: "أبيض حي", category: .chicken, subtitle: "ذبح فريش عند الطلب، تنظيف فندقي كامل", price: 135, originalPrice: nil, imageName: "prod_chicken_whole", imageURL: nil, badge: "الأكثر طلباً", isAvailable: true, isOffer: false, sizes: ["صغير", "وسط", "فوق الوسط", "كبير"], units: ["BIRD", "KILO"], prepOptions: ["WHOLE", "CUT"], allowHalfUnit: false),
        StoreProduct(id: "chk_drumsticks", name: "دبابيس دجاج", category: .cuts, subtitle: "دبابيس دجاج فريش", price: 165, originalPrice: nil, imageName: "prod_drumsticks", imageURL: nil, badge: nil, isAvailable: true, isOffer: false, sizes: [], units: ["KILO", "PIECE"], prepOptions: [], allowHalfUnit: true),
        StoreProduct(id: "duck", name: "بط فلاحي", category: .duck, subtitle: "بط فلاحي تربية بيتي، لحم طري", price: 165, originalPrice: nil, imageName: "prod_duck", imageURL: nil, badge: nil, isAvailable: true, isOffer: false, sizes: [], units: ["KILO", "BIRD"], prepOptions: ["WHOLE", "CUT"], allowHalfUnit: true),
        StoreProduct(id: "hamam", name: "حمام بلدي", category: .pigeonQuail, subtitle: "حمام بلدي مجهز ومنظف بعناية", price: 180, originalPrice: nil, imageName: "prod_hamam", imageURL: nil, badge: nil, isAvailable: true, isOffer: false, sizes: [], units: ["PAIR"], prepOptions: [], allowHalfUnit: false),
        StoreProduct(id: "pane", name: "صدور بانيه", category: .marinated, subtitle: "صدور دجاج متبلة وجاهزة للقلي", price: 225, originalPrice: nil, imageName: "prod_panee", imageURL: nil, badge: "طازج يومياً", isAvailable: true, isOffer: false, sizes: [], units: ["KILO"], prepOptions: [], allowHalfUnit: true),
        StoreProduct(id: "shish", name: "شيش طاووق", category: .marinated, subtitle: "قطع شيش بتتبيلة طيور الرشيدي", price: 220, originalPrice: nil, imageName: "prod_shish", imageURL: nil, badge: nil, isAvailable: true, isOffer: false, sizes: [], units: ["KILO"], prepOptions: [], allowHalfUnit: true),
        StoreProduct(id: "wings", name: "أجنحة دجاج", category: .cuts, subtitle: "أجنحة دجاج طازجة", price: 110, originalPrice: nil, imageName: "prod_wings", imageURL: nil, badge: nil, isAvailable: true, isOffer: false, sizes: [], units: ["KILO"], prepOptions: [], allowHalfUnit: false)
    ]
}
