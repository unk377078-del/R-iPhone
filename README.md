# طيور الرشيدي — تطبيق iOS

تطبيق SwiftUI عربي مبني على مشروع Android المرفق، مع دعم الواجهة من اليمين إلى اليسار، كتالوج Firestore، السلة المحلية، إنشاء الطلبات، الفروع، وصفحة مدير لمتابعة الطلبات.

## فتح المشروع

افتح `RashidiIOS.xcodeproj` في Xcode على جهاز Mac. المشروع يحتاج Xcode يدعم iOS 17 أو أحدث واتصال إنترنت أول مرة لتنزيل Firebase iOS SDK عبر Swift Package Manager. لتشغيل معاينة من Windows، ارفع المشروع إلى GitHub واربطه بـ Codemagic؛ ملف `codemagic.yaml` يبني نسخة iOS Simulator، ثم استخدم App Preview / Quick Launch من نتيجة البناء.

## ربط Firebase

1. في Firebase Console افتح مشروع `al-rashidi-poultry` وأضف تطبيق iOS بمعرّف الحزمة `com.alrashidi.poultry.ios` (أو عدّله في Build Settings قبل التسجيل).
2. نزّل `GoogleService-Info.plist` وضعه داخل مجموعة `RashidiIOS` في Xcode، مع تفعيل **Copy items if needed** وإضافته إلى Target التطبيق.
3. فعّل Cloud Firestore وEmail/Password في Firebase Authentication.
4. أنشئ حساب المدير عبر Firebase Authentication، ثم أنشئ يدويًا مستندًا في `admins/{Firebase Auth UID}`. لا تسمح قواعد Firestore بإنشاء مستند المدير من التطبيق.
5. راجع `firestore.rules` وطبّقها بعد التأكد من سلوك قاعدة الإنتاج وبياناتها. القواعد تسمح بإنشاء طلبات عامة للشراء دون حساب، وتقيّد القراءة والتعديل للمشرفين.

ملف إعداد Android لا يُستخدم في iOS. ملف plist غير مضمن عمدًا، ويجب تنزيله من مشروع Firebase بعد تسجيل تطبيق iOS.

## ما نُقل

- الرئيسية والكتالوج والبحث والتصنيفات وتفاصيل المنتج والتخصيص.
- سلة محفوظة على الجهاز حتى بعد إغلاق التطبيق.
- طلبات التوصيل أو الاستلام، وطرق الدفع كاش وInstapay.
- الفروع، الاتصال، فتح الاتجاهات في Apple Maps، نبذة عن المتجر.
- دخول مدير عبر Firebase Authentication والتحقق من عضويته في `admins`، ومتابعة الطلبات وتحديث حالتها.
- صور الشعار والفروع والمنتجات واللافتات الموجودة في مشروع Android.

## قبل النشر في App Store

- استخدم معرّف Bundle ID وحساب Apple Developer المملوكين لك، وحدد فريق التوقيع في Xcode.
- أضف `GoogleService-Info.plist`، أيقونة تطبيق نهائية، ولقطات شاشة ومعلومات المتجر.
- أضف روابط سياسة الخصوصية وشروط الاستخدام، واملأ App Privacy في App Store Connect وفق بياناتك الفعلية.
- فعّل Firebase App Check لـ iOS وراجع حماية Cloud Firestore، حدود الطلبات، وسياسة التعامل مع بيانات العملاء.
- اختبر التطبيق على أجهزة iPhone حقيقية، وراجع نسخة iPad أو استبعدها حسب قرارك.
- إشعارات الدفع مهيأة عبر Firebase Messaging والموضوعات `all_users`, `promotions`, `offers`. يلزم تفعيل APNs في Apple Developer ورفع مفتاح APNs إلى Firebase، ثم تفعيل قدرة Push Notifications في Target قبل استخدامها على جهاز حقيقي.

## ملاحظات على التوافق

اسماء المجموعات والحقول الأساسية تتبع تطبيق Android: `products`, `orders`, `admins`، وحقول الطلب مثل `customerName`, `customerPhone`, `items`, `total`, `status`, `createdAt`. بيانات Firebase الفعلية هي المصدر الحي للكتالوج. تظهر بيانات معاينة محلية محدودة إلى أن يُضاف plist وتُحمّل المنتجات من Firestore.

قواعد Android الأصلية داخل ZIP تسمح بالقراءة والكتابة للجميع على قاعدة البيانات بأكملها. لا تستخدم تلك القواعد في الإنتاج.
