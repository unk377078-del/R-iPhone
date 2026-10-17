import SwiftUI

@main
struct RashidiApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate
    @StateObject private var store = StoreModel()
    var body: some Scene {
        WindowGroup {
            StoreRootView()
                .environmentObject(store)
                .environment(\.layoutDirection, .rightToLeft)
                .preferredColorScheme(.light)
                .tint(Color.rashidiRed)
        }
    }
}

extension Color {
    static let rashidiRed = Color(red: 0.72, green: 0.08, blue: 0.12)
    static let rashidiInk = Color(red: 0.16, green: 0.16, blue: 0.16)
    static let rashidiCream = Color(red: 0.98, green: 0.97, blue: 0.95)
}

struct StoreRootView: View {
    @EnvironmentObject private var store: StoreModel
    @State private var selectedTab = 0
    @State private var selectedCategory: StoreCategory = .all
    @State private var selectedProduct: StoreProduct?
    @State private var showCheckout = false
    var body: some View {
        TabView(selection: $selectedTab) {
            HomeScreen(selectedTab: $selectedTab, selectedCategory: $selectedCategory, onProduct: { selectedProduct = $0 }).tabItem { Label("الرئيسية", systemImage: "house.fill") }.tag(0)
            CatalogScreen(selectedCategory: $selectedCategory, onProduct: { selectedProduct = $0 }).tabItem { Label("المنتجات", systemImage: "square.grid.2x2.fill") }.tag(1)
            CartScreen(showCheckout: $showCheckout).tabItem { Label("السلة \(store.cartCount > 0 ? "(\(store.cartCount))" : "")", systemImage: "cart.fill") }.tag(2)
            BranchesScreen().tabItem { Label("الفروع", systemImage: "mappin.and.ellipse") }.tag(3)
            AccountScreen().tabItem { Label("حسابي", systemImage: "person.crop.circle") }.tag(4)
        }
        .sheet(item: $selectedProduct) { ProductDetailSheet(product: $0) }
        .sheet(isPresented: $showCheckout) { CheckoutScreen() }
        .alert("طيور الرشيدي", isPresented: Binding(get: { store.notice != nil }, set: { if !$0 { store.notice = nil } })) {
            Button("حسناً", role: .cancel) { store.notice = nil }
        } message: { Text(store.notice ?? "") }
    }
}

struct HomeScreen: View {
    @EnvironmentObject private var store: StoreModel
    @Binding var selectedTab: Int
    @Binding var selectedCategory: StoreCategory
    let onProduct: (StoreProduct) -> Void
    private let categories = Array(StoreCategory.allCases.dropFirst())
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 22) {
                    HeaderBar()
                    ZStack(alignment: .bottomTrailing) {
                        Image("hero_chicken_banner_1790709457836").resizable().scaledToFill().frame(height: 190).frame(maxWidth: .infinity).clipped().clipShape(RoundedRectangle(cornerRadius: 22))
                        VStack(alignment: .trailing, spacing: 8) {
                            Text("طازة.. على طلبك").font(.system(size: 25, weight: .bold))
                            Text("اختار طلبك وإحنا نجهزهولك بعناية").font(.system(size: 14, weight: .medium))
                            Button("تسوق الآن") { selectedTab = 1 }.font(.system(size: 14, weight: .bold)).padding(.horizontal, 16).padding(.vertical, 9).background(Color.white).foregroundStyle(Color.rashidiRed).clipShape(Capsule())
                        }.foregroundStyle(.white).padding(18).background(LinearGradient(colors: [.clear, .black.opacity(0.66)], startPoint: .top, endPoint: .bottom)).frame(maxWidth: .infinity, alignment: .trailing).clipShape(RoundedRectangle(cornerRadius: 22))
                    }
                    HStack { Text("تسوق حسب القسم").font(.system(size: 19, weight: .bold)); Spacer(); Text("عرض الكل").font(.system(size: 13, weight: .semibold)).foregroundStyle(Color.rashidiRed) }
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 10) {
                            ForEach(categories) { category in
                                Button(category.rawValue) { selectedCategory = category; selectedTab = 1 }.font(.system(size: 14, weight: .semibold)).padding(.horizontal, 17).padding(.vertical, 11).background(Color.white).clipShape(Capsule()).overlay(Capsule().stroke(Color.black.opacity(0.06)))
                            }
                        }
                    }
                    HStack { Text("الأكثر طلباً").font(.system(size: 19, weight: .bold)); Spacer(); Image(systemName: "arrow.left").foregroundStyle(Color.rashidiRed) }
                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 13) {
                        ForEach(store.products.filter { $0.isAvailable }.prefix(6)) { product in ProductCard(product: product) { onProduct(product) } }
                    }
                    HStack(spacing: 12) {
                        Image(systemName: "clock.fill").foregroundStyle(Color.rashidiRed).font(.title2)
                        VStack(alignment: .leading, spacing: 4) { Text("من 1960 بنقدم الطازة").font(.system(size: 15, weight: .bold)); Text("طيور الرشيدي.. خبرة وجودة بتوصل لبيتك").font(.system(size: 12)).foregroundStyle(.secondary) }
                    }.padding(16).frame(maxWidth: .infinity, alignment: .leading).background(.white).clipShape(RoundedRectangle(cornerRadius: 16))
                }.padding(16)
            }.background(Color.rashidiCream).toolbar(.hidden, for: .navigationBar)
        }
    }
}

struct HeaderBar: View {
    var body: some View {
        HStack {
            Image("logo_alrashidi").resizable().scaledToFit().frame(width: 54, height: 54).clipShape(Circle())
            VStack(alignment: .leading, spacing: 3) { Text("طيور الرشيدي").font(.system(size: 18, weight: .bold)); Text("الطازة من عندنا لحد عندك").font(.system(size: 11)).foregroundStyle(.secondary) }
            Spacer()
            Image(systemName: "bell").font(.system(size: 18)).frame(width: 42, height: 42).background(.white).clipShape(Circle())
        }
    }
}

struct CatalogScreen: View {
    @EnvironmentObject private var store: StoreModel
    @Binding var selectedCategory: StoreCategory
    let onProduct: (StoreProduct) -> Void
    @State private var query = ""
    private var filtered: [StoreProduct] {
        store.products.filter { (selectedCategory == .all || $0.category == selectedCategory) && (query.isEmpty || $0.name.localizedCaseInsensitiveContains(query)) }
    }
    var body: some View {
        NavigationStack {
            VStack(spacing: 12) {
                TextField("ابحث عن منتج...", text: $query).textFieldStyle(.roundedBorder).padding(.horizontal)
                ScrollView(.horizontal, showsIndicators: false) { HStack { ForEach(StoreCategory.allCases) { item in
                    Button(item.rawValue) { selectedCategory = item }.font(.system(size: 13, weight: .semibold)).padding(.horizontal, 14).padding(.vertical, 9).background(selectedCategory == item ? Color.rashidiRed : .white).foregroundStyle(selectedCategory == item ? .white : Color.rashidiInk).clipShape(Capsule())
                } }.padding(.horizontal) }
                ScrollView { LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 13) { ForEach(filtered) { p in ProductCard(product: p) { onProduct(p) } } }.padding(16) }
            }.background(Color.rashidiCream).navigationTitle("المنتجات").navigationBarTitleDisplayMode(.inline)
        }
    }
}

struct ProductCard: View {
    @EnvironmentObject private var store: StoreModel
    let product: StoreProduct
    let tap: () -> Void
    var body: some View {
        VStack(alignment: .trailing, spacing: 8) {
            Button(action: tap) {
                ZStack(alignment: .topTrailing) {
                    productImage(product).frame(height: 132).frame(maxWidth: .infinity).background(Color.rashidiCream).clipShape(RoundedRectangle(cornerRadius: 13))
                    if let badge = product.badge { Text(badge).font(.system(size: 10, weight: .bold)).padding(.horizontal, 8).padding(.vertical, 5).background(Color.rashidiRed).foregroundStyle(.white).clipShape(Capsule()).padding(7) }
                }
            }.buttonStyle(.plain)
            Text(product.name).font(.system(size: 15, weight: .bold)).lineLimit(1)
            Text(product.displayPrice).font(.system(size: 14, weight: .heavy)).foregroundStyle(Color.rashidiRed)
            Button { store.add(product) } label: { Label("أضف للسلة", systemImage: "plus").font(.system(size: 12, weight: .bold)).frame(maxWidth: .infinity).padding(.vertical, 9).background(Color.rashidiRed).foregroundStyle(.white).clipShape(RoundedRectangle(cornerRadius: 10)) }
        }.padding(10).background(.white).clipShape(RoundedRectangle(cornerRadius: 16))
    }
}

@ViewBuilder func productImage(_ product: StoreProduct) -> some View {
    if let url = product.imageURL { AsyncImage(url: url) { image in image.resizable().scaledToFill() } placeholder: { Image(product.imageName).resizable().scaledToFill() } }
    else { Image(product.imageName).resizable().scaledToFill() }
}

struct ProductDetailSheet: View {
    @EnvironmentObject private var store: StoreModel
    @Environment(\.dismiss) private var dismiss
    let product: StoreProduct
    @State private var quantity = 1.0
    @State private var unit = "KILO"
    @State private var size = ""
    @State private var prep = ""
    @State private var notes = ""
    private var unitLabel: String { ["KILO": "كيلو", "PIECE": "قطعة", "PAIR": "جوز", "PLATE": "طبق", "BIRD": "طائر/دجاجة"][unit] ?? "كيلو" }
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .trailing, spacing: 18) {
                    productImage(product).frame(height: 240).frame(maxWidth: .infinity).clipShape(RoundedRectangle(cornerRadius: 20))
                    VStack(alignment: .trailing, spacing: 7) { Text(product.name).font(.system(size: 24, weight: .bold)); Text(product.subtitle).font(.system(size: 14)).foregroundStyle(.secondary); Text(product.displayPrice).font(.system(size: 20, weight: .heavy)).foregroundStyle(Color.rashidiRed) }
                    if !product.sizes.isEmpty { optionGroup("اختار الحجم", options: product.sizes, selection: $size) }
                    if product.units.count > 1 { optionGroup("طريقة الطلب", options: product.units.map { ["KILO": "كيلو", "PIECE": "قطعة", "PAIR": "جوز", "BIRD": "بالواحدة"][ $0 ] ?? $0 }, selection: unitDisplay) }
                    if !product.prepOptions.isEmpty { optionGroup("التجهيز", options: ["سليم", "مقطع", "خلي", "سلخ"], selection: $prep) }
                    HStack { Text("الكمية").fontWeight(.semibold); Spacer(); quantityControl }
                    TextField("ملاحظات خاصة بالتجهيز (اختياري)", text: $notes, axis: .vertical).textFieldStyle(.roundedBorder)
                    Button {
                        store.add(product, quantity: quantity, unit: unit, size: size, prep: prep, note: notes); dismiss()
                    } label: { Text("أضف للسلة  ·  \(product.price.map { String(format: "%.0f ج.م", $0 * quantity) } ?? "السعر عند الاتصال")").font(.system(size: 15, weight: .bold)).frame(maxWidth: .infinity).padding(.vertical, 15).background(Color.rashidiRed).foregroundStyle(.white).clipShape(RoundedRectangle(cornerRadius: 14)) }
                }.padding(18)
            }.background(Color.rashidiCream).toolbar { ToolbarItem(placement: .topBarTrailing) { Button("إغلاق") { dismiss() } } }
        }.presentationDetents([.large, .fraction(0.88)]).presentationDragIndicator(.visible)
    }
    private var quantityControl: some View {
        HStack(spacing: 16) { Button { quantity = max(product.allowHalfUnit ? 0.5 : 1, quantity - (product.allowHalfUnit ? 0.5 : 1)) } label: { Image(systemName: "minus.circle.fill") }; Text(quantity.formatted()).fontWeight(.bold).frame(minWidth: 30); Button { quantity += product.allowHalfUnit ? 0.5 : 1 } label: { Image(systemName: "plus.circle.fill") } }.font(.title3).foregroundStyle(Color.rashidiRed)
    }
    private var unitDisplay: Binding<String> {
        Binding(get: { ["KILO": "كيلو", "PIECE": "قطعة", "PAIR": "جوز", "PLATE": "طبق", "BIRD": "بالواحدة"][unit] ?? "كيلو" },
                set: { value in unit = ["كيلو": "KILO", "قطعة": "PIECE", "جوز": "PAIR", "طبق": "PLATE", "بالواحدة": "BIRD"][value] ?? "KILO" })
    }
    private func optionGroup(_ title: String, options: [String], selection: Binding<String>) -> some View {
        VStack(alignment: .trailing, spacing: 9) {
            Text(title).font(.system(size: 15, weight: .bold))
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(options, id: \.self) { option in
                        Button(option) { selection.wrappedValue = option }
                            .font(.system(size: 13, weight: .semibold)).padding(.horizontal, 13).padding(.vertical, 9)
                            .background(selection.wrappedValue == option ? Color.rashidiRed : Color.white)
                            .foregroundStyle(selection.wrappedValue == option ? Color.white : Color.rashidiInk)
                            .clipShape(Capsule())
                    }
                }
            }
        }
    }
}

struct CartScreen: View {
    @EnvironmentObject private var store: StoreModel
    @Binding var showCheckout: Bool
    var body: some View {
        NavigationStack {
            Group {
                if store.cart.isEmpty { ContentUnavailableView("السلة فارغة", systemImage: "cart", description: Text("أضف منتجاتك المفضلة للبدء")) }
                else { VStack(spacing: 0) {
                    List { ForEach(store.cart) { line in HStack(spacing: 12) {
                        Image(line.imageName).resizable().scaledToFill().frame(width: 70, height: 70).clipShape(RoundedRectangle(cornerRadius: 12))
                        VStack(alignment: .leading, spacing: 5) { Text(line.name).fontWeight(.bold); Text("\(line.quantity.formatted()) \(line.unitLabel)\(line.size.isEmpty ? "" : " · \(line.size)")").font(.caption).foregroundStyle(.secondary); Text(line.total.map { String(format: "%.0f ج.م", $0) } ?? "السعر عند الاتصال").font(.subheadline.bold()).foregroundStyle(Color.rashidiRed) }
                        Spacer(); VStack { Button { store.changeQuantity(line, by: 1) } label: { Image(systemName: "plus.circle") }; Text(line.quantity.formatted()).font(.caption); Button { store.changeQuantity(line, by: -1) } label: { Image(systemName: "minus.circle") } }.foregroundStyle(Color.rashidiRed)
                    }.padding(.vertical, 5) }.onDelete { offsets in offsets.map { store.cart[$0] }.forEach { store.remove($0) } } }
                    VStack(spacing: 12) { HStack { Text("المجموع"); Spacer(); Text(String(format: "%.0f ج.م", store.subtotal)).fontWeight(.bold) }; Button { showCheckout = true } label: { Text("إتمام الطلب").fontWeight(.bold).frame(maxWidth: .infinity).padding().background(Color.rashidiRed).foregroundStyle(.white).clipShape(RoundedRectangle(cornerRadius: 14)) } }.padding(18).background(.white)
                } }
            }.navigationTitle("سلة التسوق").navigationBarTitleDisplayMode(.inline).toolbar { if !store.cart.isEmpty { EditButton() } }
        }
    }
}
