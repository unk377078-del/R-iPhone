import SwiftUI

struct CheckoutScreen: View {
    @EnvironmentObject private var store: StoreModel
    @Environment(\.dismiss) private var dismiss
    @State private var name = ""
    @State private var phone = ""
    @State private var method = "توصيل للمنزل"
    @State private var address = ""
    @State private var street = ""
    @State private var buildingInfo = ""
    @State private var time = "خلال ساعتين إلى 3 ساعات"
    @State private var payment = "كاش"
    @State private var notes = ""
    @State private var sending = false
    private let areas = ["كامب شيزار", "سموحة", "جناكليس", "بحري والأنفوشي", "سيدي بشر", "جليم", "رشدي", "ستانلي", "الإبراهيمية", "كليوباترا", "لوران", "زيزينيا", "ميامي", "محرم بك", "سيدي جابر", "الشاطبي"]
    private let times = ["خلال ساعتين إلى 3 ساعات", "من 11 صباحاً إلى 1 مساءً", "من 1 مساءً إلى 3 مساءً", "من 3 مساءً إلى 5 مساءً", "من 5 مساءً إلى 8 مساءً"]
    var body: some View {
        NavigationStack {
            Form {
                Section("بيانات التواصل") {
                    TextField("الاسم بالكامل", text: $name)
                    TextField("رقم الموبايل", text: $phone).keyboardType(.phonePad)
                }
                Section("طريقة الاستلام") {
                    Picker("الطريقة", selection: $method) { Text("توصيل للمنزل").tag("توصيل للمنزل"); Text("استلام من الفرع").tag("استلام من الفرع") }
                    if method == "توصيل للمنزل" {
                        Picker("المنطقة", selection: $address) { Text("اختار المنطقة").tag(""); ForEach(areas, id: \.self) { Text($0).tag($0) } }
                        TextField("الشارع", text: $street)
                        TextField("رقم العقار / الدور / الشقة", text: $buildingInfo)
                    }
                    else { Picker("الفرع", selection: $address) { ForEach(StoreBranches.all) { Text($0.name).tag($0.name) } } }
                    Picker("موعد الاستلام", selection: $time) { ForEach(times, id: \.self) { Text($0).tag($0) } }
                }
                Section("الدفع") { Picker("طريقة الدفع", selection: $payment) { Text("كاش عند الاستلام").tag("كاش"); Text("Instapay").tag("Instapay") } }
                Section("ملاحظات") { TextField("تفاصيل العنوان أو تعليمات إضافية", text: $notes, axis: .vertical).lineLimit(2...5) }
                Section { HStack { Text("الإجمالي").fontWeight(.semibold); Spacer(); Text(String(format: "%.0f ج.م", store.subtotal)).fontWeight(.bold).foregroundStyle(Color.rashidiRed) } }
                Section { Button { Task { sending = true; let success = await store.submitOrder(name: name, phone: phone, method: method, address: address, street: street, buildingInfo: buildingInfo, time: time, payment: payment, notes: notes); sending = false; if success { dismiss() } } } label: { HStack { Spacer(); if sending { ProgressView() } else { Text("تأكيد الطلب").fontWeight(.bold) }; Spacer() } }.disabled(sending || store.cart.isEmpty) }
            }.navigationTitle("تأكيد الطلب").navigationBarTitleDisplayMode(.inline).toolbar { ToolbarItem(placement: .topBarLeading) { Button("إلغاء") { dismiss() } } }
        }
    }
}

struct BranchesScreen: View {
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 14) {
                    ForEach(StoreBranches.all) { branch in
                        VStack(alignment: .trailing, spacing: 12) {
                            Image(branch.image).resizable().scaledToFill().frame(height: 165).frame(maxWidth: .infinity).clipped().clipShape(RoundedRectangle(cornerRadius: 14))
                            Text(branch.name).font(.system(size: 18, weight: .bold))
                            Label(branch.address, systemImage: "mappin.and.ellipse").font(.system(size: 14)).foregroundStyle(.secondary)
                            Label(branch.hours, systemImage: "clock").font(.system(size: 13)).foregroundStyle(.secondary)
                            HStack {
                                Link(destination: URL(string: "tel:\(branch.phone)")!) { Label("اتصل بالفرع", systemImage: "phone.fill").frame(maxWidth: .infinity).padding(11).background(Color.rashidiRed).foregroundStyle(.white).clipShape(RoundedRectangle(cornerRadius: 11)) }
                                Link(destination: URL(string: "https://maps.apple.com/?q=طيور+الرشيدي+\(branch.address.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "")")!) { Label("الاتجاهات", systemImage: "map.fill").frame(maxWidth: .infinity).padding(11).background(Color.rashidiCream).foregroundStyle(Color.rashidiInk).clipShape(RoundedRectangle(cornerRadius: 11)) }
                            }.font(.system(size: 13, weight: .semibold))
                        }.padding(14).background(.white).clipShape(RoundedRectangle(cornerRadius: 18))
                    }
                }.padding(16)
            }.background(Color.rashidiCream).navigationTitle("فروعنا").navigationBarTitleDisplayMode(.inline)
        }
    }
}

struct AccountScreen: View {
    @EnvironmentObject private var store: StoreModel
    @State private var showAdmin = false
    var body: some View {
        NavigationStack {
            List {
                Section {
                    HStack(spacing: 14) { Image("logo_alrashidi").resizable().scaledToFit().frame(width: 60, height: 60).clipShape(Circle()); VStack(alignment: .leading) { Text("طيور الرشيدي").font(.headline); Text("من 1960 في خدمتكم").font(.subheadline).foregroundStyle(.secondary) } }
                }
                Section("خدمة العملاء") {
                    Link(destination: URL(string: "tel:01223381405")!) { Label("اتصل بنا", systemImage: "phone.fill") }
                    Link(destination: URL(string: "https://wa.me/201223381405")!) { Label("تواصل عبر واتساب", systemImage: "message.fill") }
                    NavigationLink { AboutScreen() } label: { Label("عن طيور الرشيدي", systemImage: "info.circle") }
                }
                Section("إدارة المتجر") {
                    Button { showAdmin = true } label: { Label("دخول لوحة التحكم", systemImage: "lock.shield") }
                    if !store.adminEmail.isEmpty { Button("تسجيل خروج المدير", role: .destructive) { store.signOut() } }
                }
                Section { Text("الأسعار والتوفر قد يتغيران حسب السوق. سيتم تأكيد تفاصيل طلبك من الفرع.").font(.footnote).foregroundStyle(.secondary) }
            }.navigationTitle("حسابي").navigationBarTitleDisplayMode(.inline).sheet(isPresented: $showAdmin) { AdminLoginScreen() }
        }
    }
}

struct AboutScreen: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .trailing, spacing: 18) {
                Image("alrashidi_rooster_logo_1790107857402").resizable().scaledToFit().frame(height: 190).frame(maxWidth: .infinity).background(.white).clipShape(RoundedRectangle(cornerRadius: 20))
                Text("طيور الرشيدي").font(.system(size: 24, weight: .bold))
                Text("منذ عام 1960، نقدم لكم أجود أنواع الدواجن والطيور الطازجة، مع تجهيز دقيق وخدمة توصيل في الإسكندرية.").font(.system(size: 16)).lineSpacing(5)
                Text("نختار منتجاتنا بعناية ونجهز كل طلب حسب رغبتك، لتصلك الجودة التي تثق بها الأسرة المصرية.").font(.system(size: 15)).foregroundStyle(.secondary).lineSpacing(4)
                HStack { Image(systemName: "location.fill"); Text("الإسكندرية، جمهورية مصر العربية") }.foregroundStyle(Color.rashidiRed)
            }.padding(20)
        }.background(Color.rashidiCream).navigationTitle("عن المتجر").navigationBarTitleDisplayMode(.inline)
    }
}

struct AdminLoginScreen: View {
    @EnvironmentObject private var store: StoreModel
    @Environment(\.dismiss) private var dismiss
    @State private var email = ""
    @State private var password = ""
    @State private var loading = false
    var body: some View {
        NavigationStack {
            Group {
                if !store.adminEmail.isEmpty { AdminOrdersScreen() }
                else { Form {
                    Section("حساب المدير") { TextField("البريد الإلكتروني", text: $email).textInputAutocapitalization(.never).keyboardType(.emailAddress); SecureField("كلمة المرور", text: $password) }
                    Section { Button { Task { loading = true; if await store.signInAdmin(email: email, password: password) { } ; loading = false } } label: { HStack { Spacer(); if loading { ProgressView() } else { Text("تسجيل الدخول") }; Spacer() } }.disabled(loading || email.isEmpty || password.isEmpty) }
                    Section { Text("الدخول متاح للحسابات التي أضيفت إلى Firebase Authentication ومجموعة admins فقط.").font(.footnote).foregroundStyle(.secondary) }
                } }
            }.navigationTitle("لوحة التحكم").navigationBarTitleDisplayMode(.inline).toolbar { ToolbarItem(placement: .topBarLeading) { Button("إغلاق") { dismiss() } } }
        }
    }
}

struct AdminOrdersScreen: View {
    @EnvironmentObject private var store: StoreModel
    private let statuses = ["قيد المراجعة والتجهيز", "جاري التجهيز", "خرج للتوصيل", "تم التسليم", "ملغي"]
    var body: some View {
        List {
            Section { HStack { Text("الطلبات").fontWeight(.bold); Spacer(); Text("\(store.orders.count)").foregroundStyle(Color.rashidiRed) } }
            ForEach(store.orders) { order in
                VStack(alignment: .trailing, spacing: 8) {
                    HStack { Text("طلب #\(order.id)").fontWeight(.bold); Spacer(); Text(order.status).font(.caption.bold()).foregroundStyle(Color.rashidiRed) }
                    Text("\(order.customerName) · \(order.customerPhone)").font(.subheadline)
                    Text(order.summary).font(.caption).foregroundStyle(.secondary).lineLimit(2)
                    HStack { Text(String(format: "%.0f ج.م", order.total)).fontWeight(.bold); Spacer(); Menu("تحديث الحالة") { ForEach(statuses, id: \.self) { status in Button(status) { Task { await store.updateStatus(order, status: status) } } } }.font(.caption.bold()) }
                }.padding(.vertical, 5)
            }
        }
    }
}
