import 'package:flutter/material.dart';

/// موضوع في «دليل الاستخدام» التفاعليّ: عنوان + شرح تفصيليّ، مترجَمان.
/// الرجوع: لغة المستخدم ← الإنجليزية ← العربية.
class GuideTopic {
  final String id;
  final IconData icon;
  final Map<String, String> title;
  final Map<String, String> body;
  const GuideTopic(this.id, this.icon, this.title, this.body);

  String localizedTitle(String lang) =>
      title[lang] ?? title['en'] ?? title['ar'] ?? id;
  String localizedBody(String lang) =>
      body[lang] ?? body['en'] ?? body['ar'] ?? '';
}

/// مواضيع الدليل بالترتيب. الشرح مفصّل في: العربية، الإنجليزية، التركية،
/// الإسبانية، الفارسية، الإندونيسية، الفرنسية، الألمانية — ويرجع للإنجليزية في غيرها.
const List<GuideTopic> guideTopics = [
  GuideTopic(
    'start',
    Icons.rocket_launch_outlined,
    {
      'ar': 'البدء السريع',
      'en': 'Getting started',
      'tr': 'Hızlı başlangıç',
      'es': 'Primeros pasos',
      'fa': 'شروع سریع',
      'id': 'Memulai',
      'fr': 'Premiers pas',
      'de': 'Erste Schritte',
    },
    {
      'ar': 'تطبيق «ملاحظات» يعمل دون إنترنت بالكامل، ويحفظ كل شيء داخل جهازك '
          'في قاعدة بيانات مشفّرة.\n\n'
          '١) اضغط زرّ + في الأسفل لإضافة ملاحظة، واختر نوعها.\n'
          '٢) اكتب — تُحفظ ملاحظتك تلقائيًّا أثناء الكتابة (لا حاجة لزرّ حفظ).\n'
          '٣) ارجع للرئيسية بزرّ الرجوع؛ ستجد ملاحظتك في الأعلى.\n'
          '٤) يُنصح بتفعيل «قفل التطبيق» و«النسخ الاحتياطي» من الإعدادات لحماية بياناتك.',
      'en': 'Notes works fully offline and keeps everything on your device in an '
          'encrypted database.\n\n'
          '1) Tap the + button at the bottom to add a note and choose its type.\n'
          '2) Start typing — your note is saved automatically as you write (no save button).\n'
          '3) Go back; your note appears at the top of the home screen.\n'
          '4) We recommend enabling App Lock and Backup from Settings to protect your data.',
      'tr': 'Notlar tamamen çevrimdışı çalışır ve her şeyi cihazınızda şifreli bir '
          'veritabanında saklar.\n\n'
          '1) Not eklemek için alttaki + düğmesine dokunun ve türünü seçin.\n'
          '2) Yazmaya başlayın — notunuz siz yazarken otomatik kaydedilir.\n'
          '3) Geri dönün; notunuz ana ekranın üstünde görünür.\n'
          '4) Verilerinizi korumak için Ayarlar’dan Uygulama Kilidi ve Yedekleme’yi açmanızı öneririz.',
      'es': 'Notas funciona totalmente sin conexión y guarda todo en tu dispositivo '
          'en una base de datos cifrada.\n\n'
          '1) Toca el botón + abajo para añadir una nota y elige su tipo.\n'
          '2) Empieza a escribir — la nota se guarda automáticamente.\n'
          '3) Vuelve atrás; tu nota aparece arriba en la pantalla principal.\n'
          '4) Recomendamos activar el Bloqueo de la app y la Copia de seguridad en Ajustes.',
      'fa': 'برنامهٔ «یادداشت‌ها» کاملاً آفلاین کار می‌کند و همه چیز را در دستگاه شما '
          'در یک پایگاه‌دادهٔ رمزگذاری‌شده نگه می‌دارد.\n\n'
          '۱) دکمهٔ + پایین را بزنید تا یادداشت بیفزایید و نوع آن را انتخاب کنید.\n'
          '۲) شروع به نوشتن کنید — یادداشت هنگام نوشتن به‌طور خودکار ذخیره می‌شود.\n'
          '۳) بازگردید؛ یادداشت در بالای صفحهٔ اصلی دیده می‌شود.\n'
          '۴) توصیه می‌کنیم «قفل برنامه» و «پشتیبان‌گیری» را از تنظیمات فعال کنید.',
      'id': 'Notes bekerja sepenuhnya offline dan menyimpan semuanya di perangkat '
          'Anda dalam basis data terenkripsi.\n\n'
          '1) Ketuk tombol + di bawah untuk menambah catatan dan pilih jenisnya.\n'
          '2) Mulai mengetik — catatan tersimpan otomatis saat Anda menulis.\n'
          '3) Kembali; catatan Anda muncul di atas layar utama.\n'
          '4) Sebaiknya aktifkan Kunci Aplikasi dan Pencadangan di Pengaturan.',
      'fr': "Notes fonctionne entièrement hors ligne et conserve tout sur votre "
          "appareil dans une base de données chiffrée.\n\n"
          "1) Appuyez sur le bouton + en bas pour ajouter une note et choisissez son type.\n"
          "2) Commencez à écrire — la note est enregistrée automatiquement.\n"
          "3) Revenez en arrière ; votre note apparaît en haut de l'écran principal.\n"
          "4) Nous recommandons d'activer le Verrouillage et la Sauvegarde dans les Réglages.",
      'de': 'Notes funktioniert vollständig offline und speichert alles auf Ihrem '
          'Gerät in einer verschlüsselten Datenbank.\n\n'
          '1) Tippen Sie unten auf +, um eine Notiz hinzuzufügen, und wählen Sie den Typ.\n'
          '2) Beginnen Sie zu schreiben — die Notiz wird automatisch gespeichert.\n'
          '3) Gehen Sie zurück; Ihre Notiz erscheint oben im Hauptbildschirm.\n'
          '4) Wir empfehlen, App-Sperre und Sicherung in den Einstellungen zu aktivieren.',
    },
  ),
  GuideTopic(
    'types',
    Icons.category_outlined,
    {
      'ar': 'أنواع الملاحظات',
      'en': 'Note types',
      'tr': 'Not türleri',
      'es': 'Tipos de notas',
      'fa': 'انواع یادداشت',
      'id': 'Jenis catatan',
      'fr': 'Types de notes',
      'de': 'Notiztypen',
    },
    {
      'ar': 'عند الضغط على + تختار نوع الملاحظة:\n\n'
          '• نصية: نصّ غنيّ كامل التنسيق (الافتراضي).\n'
          '• قائمة مهام: عناصر بمربّعات تأشير ✓ مع شريط تقدّم.\n'
          '• صورة: من الكاميرا أو المعرض.\n'
          '• صوتية: تسجيل صوتيّ داخل الملاحظة.\n'
          '• PDF: إرفاق ملفّ PDF وفتحه.\n'
          '• رسم: لوحة رسم/خطّ يدويّ.\n'
          '• كلمات مرور: حقول منظّمة، الحقل الحسّاس مشفّر والملاحظة مقفلة افتراضيًّا.',
      'en': 'When you tap +, choose the note type:\n\n'
          '• Text: full rich-text note (default).\n'
          '• Checklist: items with checkboxes ✓ and a progress bar.\n'
          '• Image: from camera or gallery.\n'
          '• Voice: record audio inside the note.\n'
          '• PDF: attach and open a PDF file.\n'
          '• Drawing: a handwriting/sketch canvas.\n'
          '• Passwords: structured fields; the secret field is encrypted and the note is locked by default.',
      'tr': '+ düğmesine dokununca not türünü seçersiniz:\n\n'
          '• Metin: tam zengin metin notu (varsayılan).\n'
          '• Liste: onay kutulu ✓ öğeler ve ilerleme çubuğu.\n'
          '• Görsel: kameradan veya galeriden.\n'
          '• Sesli: not içinde ses kaydı.\n'
          '• PDF: bir PDF dosyası ekleyip açma.\n'
          '• Çizim: el yazısı/çizim tuvali.\n'
          '• Parolalar: yapılandırılmış alanlar; gizli alan şifrelidir ve not varsayılan olarak kilitlidir.',
      'es': 'Al tocar +, elige el tipo de nota:\n\n'
          '• Texto: nota de texto enriquecido (predeterminado).\n'
          '• Lista: elementos con casillas ✓ y barra de progreso.\n'
          '• Imagen: desde la cámara o la galería.\n'
          '• Voz: graba audio dentro de la nota.\n'
          '• PDF: adjunta y abre un archivo PDF.\n'
          '• Dibujo: lienzo para dibujar/escribir a mano.\n'
          '• Contraseñas: campos estructurados; el campo secreto se cifra y la nota se bloquea por defecto.',
      'fa': 'با زدن +، نوع یادداشت را انتخاب می‌کنید:\n\n'
          '• متنی: یادداشت متنی کامل با قالب‌بندی (پیش‌فرض).\n'
          '• فهرست کارها: موارد با کادر تیک ✓ و نوار پیشرفت.\n'
          '• تصویر: از دوربین یا گالری.\n'
          '• صوتی: ضبط صدا درون یادداشت.\n'
          '• PDF: پیوست و باز کردن فایل PDF.\n'
          '• نقاشی: بوم نقاشی/دست‌نوشته.\n'
          '• گذرواژه‌ها: فیلدهای ساختارمند؛ فیلد حساس رمزگذاری شده و یادداشت به‌طور پیش‌فرض قفل است.',
      'id': 'Saat menekan +, pilih jenis catatan:\n\n'
          '• Teks: catatan teks kaya penuh (bawaan).\n'
          '• Daftar: item dengan kotak centang ✓ dan bilah kemajuan.\n'
          '• Gambar: dari kamera atau galeri.\n'
          '• Suara: rekam audio di dalam catatan.\n'
          '• PDF: lampirkan dan buka berkas PDF.\n'
          '• Gambar tangan: kanvas untuk menggambar/menulis tangan.\n'
          '• Kata sandi: bidang terstruktur; bidang rahasia dienkripsi dan catatan terkunci secara bawaan.',
      'fr': "En appuyant sur +, choisissez le type de note :\n\n"
          "• Texte : note en texte enrichi (par défaut).\n"
          "• Liste : éléments avec cases à cocher ✓ et barre de progression.\n"
          "• Image : depuis l'appareil photo ou la galerie.\n"
          "• Voix : enregistrement audio dans la note.\n"
          "• PDF : joindre et ouvrir un fichier PDF.\n"
          "• Dessin : une zone de dessin/écriture manuscrite.\n"
          "• Mots de passe : champs structurés ; le champ secret est chiffré et la note est verrouillée par défaut.",
      'de': 'Beim Tippen auf + wählen Sie den Notiztyp:\n\n'
          '• Text: Notiz mit voller Formatierung (Standard).\n'
          '• Checkliste: Einträge mit Kästchen ✓ und Fortschrittsbalken.\n'
          '• Bild: aus Kamera oder Galerie.\n'
          '• Sprache: Audioaufnahme in der Notiz.\n'
          '• PDF: eine PDF-Datei anhängen und öffnen.\n'
          '• Zeichnung: eine Zeichen-/Handschriftfläche.\n'
          '• Passwörter: strukturierte Felder; das geheime Feld ist verschlüsselt und die Notiz ist standardmäßig gesperrt.',
    },
  ),
  GuideTopic(
    'editor',
    Icons.text_format,
    {
      'ar': 'المحرّر والتنسيق',
      'en': 'Editor & formatting',
      'tr': 'Düzenleyici ve biçimlendirme',
      'es': 'Editor y formato',
      'fa': 'ویرایشگر و قالب‌بندی',
      'id': 'Editor & format',
      'fr': 'Éditeur et mise en forme',
      'de': 'Editor & Formatierung',
    },
    {
      'ar': 'حدّد النصّ ثم استخدم شريط الأدوات:\n\n'
          '• غامق/مائل/تحته خطّ/يتوسّطه خطّ، ألوان نصّ وتظليل.\n'
          '• عناوين، قوائم نقطية ومرقّمة، اقتباس، كتلة شيفرة، مهامّ.\n'
          '• محاذاة (يمين/وسط/يسار) وتباعد الأسطر.\n'
          '• اتجاه ذكيّ لكل سطر: يكتشف العربية/الإنجليزية تلقائيًّا.\n'
          '• تصدير الملاحظة PDF أو Word، أو مشاركتها كصورة.\n'
          '• خصّص الأزرار الظاهرة من: الإعدادات ← الملاحظات والمحرّر ← أزرار شريط التنسيق.',
      'en': 'Select text, then use the toolbar:\n\n'
          '• Bold/italic/underline/strikethrough, text and highlight colors.\n'
          '• Headings, bulleted & numbered lists, quote, code block, tasks.\n'
          '• Alignment (right/center/left) and line spacing.\n'
          '• Smart per-line direction: auto-detects Arabic/English.\n'
          '• Export the note as PDF or Word, or share it as an image.\n'
          '• Customize visible buttons in: Settings → Notes & Editor → Toolbar buttons.',
      'tr': 'Metni seçin, sonra araç çubuğunu kullanın:\n\n'
          '• Kalın/italik/altı çizili/üstü çizili, metin ve vurgu renkleri.\n'
          '• Başlıklar, madde/numaralı listeler, alıntı, kod bloğu, görevler.\n'
          '• Hizalama (sağ/orta/sol) ve satır aralığı.\n'
          '• Akıllı satır yönü: Arapça/İngilizce’yi otomatik algılar.\n'
          '• Notu PDF veya Word olarak dışa aktarın ya da görsel olarak paylaşın.\n'
          '• Görünür düğmeleri özelleştirin: Ayarlar → Notlar ve Düzenleyici → Araç çubuğu düğmeleri.',
      'es': 'Selecciona texto y usa la barra de herramientas:\n\n'
          '• Negrita/cursiva/subrayado/tachado, colores de texto y resaltado.\n'
          '• Títulos, listas con viñetas y numeradas, cita, bloque de código, tareas.\n'
          '• Alineación (derecha/centro/izquierda) y espaciado.\n'
          '• Dirección inteligente por línea: detecta árabe/inglés.\n'
          '• Exporta la nota como PDF o Word, o compártela como imagen.\n'
          '• Personaliza los botones en: Ajustes → Notas y editor → Botones de la barra.',
      'fa': 'متن را انتخاب کنید، سپس از نوار ابزار استفاده کنید:\n\n'
          '• پررنگ/کج/زیرخط/خط‌خورده، رنگ متن و هایلایت.\n'
          '• سرفصل‌ها، فهرست نقطه‌ای و شماره‌دار، نقل‌قول، بلوک کد، کارها.\n'
          '• چینش (راست/وسط/چپ) و فاصلهٔ خطوط.\n'
          '• جهت هوشمند هر خط: فارسی/انگلیسی را خودکار تشخیص می‌دهد.\n'
          '• خروجی PDF یا Word، یا اشتراک‌گذاری به‌صورت تصویر.\n'
          '• دکمه‌های نمایان را تنظیم کنید: تنظیمات ← یادداشت‌ها و ویرایشگر ← دکمه‌های نوار ابزار.',
      'id': 'Pilih teks, lalu gunakan bilah alat:\n\n'
          '• Tebal/miring/garis bawah/coret, warna teks dan sorotan.\n'
          '• Judul, daftar berbutir & bernomor, kutipan, blok kode, tugas.\n'
          '• Perataan (kanan/tengah/kiri) dan jarak baris.\n'
          '• Arah cerdas per baris: mendeteksi Arab/Inggris otomatis.\n'
          '• Ekspor catatan sebagai PDF atau Word, atau bagikan sebagai gambar.\n'
          '• Sesuaikan tombol di: Pengaturan → Catatan & Editor → Tombol bilah alat.',
      'fr': "Sélectionnez du texte, puis utilisez la barre d'outils :\n\n"
          "• Gras/italique/souligné/barré, couleurs de texte et de surlignage.\n"
          "• Titres, listes à puces et numérotées, citation, bloc de code, tâches.\n"
          "• Alignement (droite/centre/gauche) et interligne.\n"
          "• Direction intelligente par ligne : détecte l'arabe/l'anglais.\n"
          "• Exportez la note en PDF ou Word, ou partagez-la comme image.\n"
          "• Personnalisez les boutons dans : Réglages → Notes et éditeur → Boutons de la barre.",
      'de': 'Text auswählen, dann die Symbolleiste verwenden:\n\n'
          '• Fett/kursiv/unterstrichen/durchgestrichen, Text- und Markierungsfarben.\n'
          '• Überschriften, Aufzählungs- und nummerierte Listen, Zitat, Codeblock, Aufgaben.\n'
          '• Ausrichtung (rechts/mitte/links) und Zeilenabstand.\n'
          '• Intelligente Zeilenrichtung: erkennt Arabisch/Englisch automatisch.\n'
          '• Notiz als PDF oder Word exportieren oder als Bild teilen.\n'
          '• Sichtbare Schaltflächen anpassen: Einstellungen → Notizen & Editor → Symbolleisten-Schaltflächen.',
    },
  ),
  GuideTopic(
    'organize',
    Icons.folder_outlined,
    {
      'ar': 'التنظيم: التصنيفات والوسوم والألوان',
      'en': 'Organize: categories, tags, colors',
      'tr': 'Düzenleme: kategoriler, etiketler, renkler',
      'es': 'Organizar: categorías, etiquetas, colores',
      'fa': 'سازمان‌دهی: دسته‌ها، برچسب‌ها، رنگ‌ها',
      'id': 'Atur: kategori, tag, warna',
      'fr': 'Organiser : catégories, tags, couleurs',
      'de': 'Organisieren: Kategorien, Tags, Farben',
    },
    {
      'ar': '• التصنيفات: صنّف ملاحظاتك (شخصي/عمل/أفكار…)؛ أدِرها من الإعدادات ← التنظيم ← إدارة التصنيفات.\n'
          '• الوسوم (#): أضِف وسومًا حرّة من شاشة الملاحظة. اضغط مطوّلًا على وسم لتغيير لونه.\n'
          '• الألوان والتدرّجات: من زرّ اللون داخل الملاحظة — لون أو تدرّج + نمط صفحة (تسطير).\n'
          '• التثبيت ⭐ والمفضّلة: ثبّت المهمّ في الأعلى، واجمع المفضّلة في قسمها.\n'
          '• التحديد المتعدّد: اضغط مطوّلًا على بطاقة لتحديد عدّة ملاحظات وتنفيذ إجراء جماعيّ.',
      'en': '• Categories: classify notes (personal/work/ideas…); manage them in Settings → Organize → Manage categories.\n'
          '• Tags (#): add free tags from the note screen. Long-press a tag to change its color.\n'
          '• Colors & gradients: from the color button inside a note — a color or gradient + page style (ruling).\n'
          '• Pin ⭐ & favorites: pin important notes to the top; collect favorites in their section.\n'
          '• Multi-select: long-press a card to select several notes and apply a bulk action.',
      'tr': '• Kategoriler: notları sınıflandırın (kişisel/iş/fikirler…); Ayarlar → Düzenleme → Kategorileri yönet.\n'
          '• Etiketler (#): not ekranından serbest etiket ekleyin. Rengini değiştirmek için etikete uzun basın.\n'
          '• Renkler ve geçişler: not içindeki renk düğmesinden — renk veya geçiş + sayfa stili (çizgiler).\n'
          '• Sabitle ⭐ ve favoriler: önemli notları üste sabitleyin; favorileri kendi bölümünde toplayın.\n'
          '• Çoklu seçim: birden çok notu seçip toplu işlem için bir karta uzun basın.',
      'es': '• Categorías: clasifica notas (personal/trabajo/ideas…); gestiónalas en Ajustes → Organizar → Gestionar categorías.\n'
          '• Etiquetas (#): añade etiquetas libres desde la nota. Mantén pulsada una etiqueta para cambiar su color.\n'
          '• Colores y degradados: desde el botón de color dentro de una nota — color o degradado + estilo de página.\n'
          '• Fijar ⭐ y favoritos: fija lo importante arriba; reúne los favoritos en su sección.\n'
          '• Selección múltiple: mantén pulsada una tarjeta para seleccionar varias y aplicar una acción en lote.',
      'fa': '• دسته‌ها: یادداشت‌ها را دسته‌بندی کنید (شخصی/کاری/ایده‌ها…)؛ از تنظیمات ← سازمان‌دهی ← مدیریت دسته‌ها.\n'
          '• برچسب‌ها (#): از صفحهٔ یادداشت برچسب آزاد بیفزایید. برای تغییر رنگ، روی برچسب نگه دارید.\n'
          '• رنگ‌ها و گرادیان‌ها: از دکمهٔ رنگ درون یادداشت — رنگ یا گرادیان + سبک صفحه (خط‌کشی).\n'
          '• سنجاق ⭐ و علاقه‌مندی‌ها: مهم‌ها را بالا سنجاق کنید؛ علاقه‌مندی‌ها در بخش خود.\n'
          '• انتخاب چندتایی: روی یک کارت نگه دارید تا چند یادداشت را انتخاب و عملیات گروهی اجرا کنید.',
      'id': '• Kategori: klasifikasikan catatan (pribadi/kerja/ide…); kelola di Pengaturan → Atur → Kelola kategori.\n'
          '• Tag (#): tambahkan tag bebas dari layar catatan. Tekan lama tag untuk ganti warnanya.\n'
          '• Warna & gradien: dari tombol warna di dalam catatan — warna atau gradien + gaya halaman (garis).\n'
          '• Sematkan ⭐ & favorit: sematkan yang penting ke atas; kumpulkan favorit di bagiannya.\n'
          '• Pilih banyak: tekan lama kartu untuk memilih beberapa catatan dan terapkan aksi massal.',
      'fr': "• Catégories : classez les notes (perso/travail/idées…) ; gérez-les dans Réglages → Organiser → Gérer les catégories.\n"
          "• Tags (#) : ajoutez des tags libres depuis la note. Appui long sur un tag pour changer sa couleur.\n"
          "• Couleurs et dégradés : depuis le bouton couleur dans une note — couleur ou dégradé + style de page (lignes).\n"
          "• Épingler ⭐ et favoris : épinglez l'important en haut ; regroupez les favoris dans leur section.\n"
          "• Sélection multiple : appui long sur une carte pour sélectionner plusieurs notes et appliquer une action groupée.",
      'de': '• Kategorien: Notizen einordnen (privat/Arbeit/Ideen…); verwalten in Einstellungen → Organisieren → Kategorien verwalten.\n'
          '• Tags (#): freie Tags aus der Notiz hinzufügen. Lang auf ein Tag drücken, um die Farbe zu ändern.\n'
          '• Farben & Verläufe: über die Farbschaltfläche in einer Notiz — Farbe oder Verlauf + Seitenstil (Linien).\n'
          '• Anheften ⭐ & Favoriten: Wichtiges nach oben anheften; Favoriten in ihrem Bereich sammeln.\n'
          '• Mehrfachauswahl: lang auf eine Karte drücken, um mehrere Notizen auszuwählen und eine Sammelaktion anzuwenden.',
    },
  ),
  GuideTopic(
    'search',
    Icons.search,
    {
      'ar': 'البحث والفلترة',
      'en': 'Search & filtering',
      'tr': 'Arama ve filtreleme',
      'es': 'Búsqueda y filtros',
      'fa': 'جستجو و فیلتر',
      'id': 'Cari & filter',
      'fr': 'Recherche et filtres',
      'de': 'Suche & Filter',
    },
    {
      'ar': '• البحث الفوريّ: اضغط أيقونة العدسة 🔍 في الأعلى وابحث في العنوان والمحتوى.\n'
          '• الفلترة المتقدّمة: من قائمة الخيارات — صفِّ بحسب التصنيف، الوسم، اللون، النوع، '
          'وجود صورة/صوت/PDF، ونطاق تاريخ.\n'
          '• الفرز: الأحدث تعديلًا، الأحدث/الأقدم إنشاءً، أو العنوان (أ–ي).',
      'en': '• Instant search: tap the 🔍 icon at the top to search titles and content.\n'
          '• Advanced filter: from the options menu — filter by category, tag, color, type, '
          'presence of image/audio/PDF, and date range.\n'
          '• Sorting: recently edited, newest/oldest created, or title (A–Z).',
      'tr': '• Anlık arama: üstteki 🔍 simgesine dokunup başlık ve içerikte arayın.\n'
          '• Gelişmiş filtre: seçenekler menüsünden — kategori, etiket, renk, tür, '
          'görsel/ses/PDF varlığı ve tarih aralığına göre filtreleyin.\n'
          '• Sıralama: son düzenlenen, en yeni/en eski oluşturulan veya başlık (A–Z).',
      'es': '• Búsqueda instantánea: toca el icono 🔍 arriba para buscar en títulos y contenido.\n'
          '• Filtro avanzado: desde el menú de opciones — por categoría, etiqueta, color, tipo, '
          'presencia de imagen/audio/PDF y rango de fechas.\n'
          '• Orden: editado recientemente, creado más nuevo/antiguo o título (A–Z).',
      'fa': '• جستجوی فوری: روی نماد ذره‌بین 🔍 در بالا بزنید و در عنوان و محتوا بگردید.\n'
          '• فیلتر پیشرفته: از منوی گزینه‌ها — بر اساس دسته، برچسب، رنگ، نوع، '
          'وجود تصویر/صدا/PDF و بازهٔ تاریخ.\n'
          '• مرتب‌سازی: آخرین ویرایش، جدیدترین/قدیمی‌ترین ساخت، یا عنوان (الفبا).',
      'id': '• Pencarian instan: ketuk ikon 🔍 di atas untuk mencari di judul dan isi.\n'
          '• Filter lanjutan: dari menu opsi — berdasarkan kategori, tag, warna, jenis, '
          'keberadaan gambar/audio/PDF, dan rentang tanggal.\n'
          '• Urutkan: baru diedit, terbaru/terlama dibuat, atau judul (A–Z).',
      'fr': "• Recherche instantanée : touchez l'icône 🔍 en haut pour chercher dans les titres et le contenu.\n"
          "• Filtre avancé : depuis le menu d'options — par catégorie, tag, couleur, type, "
          "présence d'image/audio/PDF et plage de dates.\n"
          "• Tri : récemment modifié, créé le plus récent/ancien, ou titre (A–Z).",
      'de': '• Sofortsuche: oben auf das Symbol 🔍 tippen, um Titel und Inhalt zu durchsuchen.\n'
          '• Erweiterter Filter: aus dem Optionsmenü — nach Kategorie, Tag, Farbe, Typ, '
          'Vorhandensein von Bild/Audio/PDF und Datumsbereich.\n'
          '• Sortierung: zuletzt bearbeitet, neueste/älteste erstellt oder Titel (A–Z).',
    },
  ),
  GuideTopic(
    'security',
    Icons.lock_outline,
    {
      'ar': 'الأمان والقفل',
      'en': 'Security & lock',
      'tr': 'Güvenlik ve kilit',
      'es': 'Seguridad y bloqueo',
      'fa': 'امنیت و قفل',
      'id': 'Keamanan & kunci',
      'fr': 'Sécurité et verrouillage',
      'de': 'Sicherheit & Sperre',
    },
    {
      'ar': 'كل بياناتك محليّة ومشفّرة. للحماية الإضافية:\n\n'
          '• قفل التطبيق: الإعدادات ← الأمان والبيانات ← الأمان → فعّل القفل واضبط رقمًا سرّيًّا، '
          'وفعّل البصمة/الوجه إن رغبت. سيُطلب عند فتح التطبيق.\n'
          '• قفل ملاحظة بعينها: من خيارات الملاحظة (اضغط مطوّلًا) → قفل.\n'
          '• القسم السرّي: ملاحظات مخفيّة لا تظهر إلا بعد فكّ القفل.\n'
          '• ملاحظات كلمات المرور والمقفلة: يُمنع تصوير شاشتها تلقائيًّا.',
      'en': 'All your data is local and encrypted. For extra protection:\n\n'
          '• App lock: Settings → Security & data → Security → enable the lock and set a PIN, '
          'and enable biometrics if you like. It is requested when opening the app.\n'
          '• Lock a specific note: from the note options (long-press) → Lock.\n'
          '• Secret section: hidden notes that only appear after unlocking.\n'
          '• Password notes and locked notes: screenshots are blocked automatically.',
      'tr': 'Tüm verileriniz yereldir ve şifrelidir. Ek koruma için:\n\n'
          '• Uygulama kilidi: Ayarlar → Güvenlik ve veriler → Güvenlik → kilidi açın ve bir PIN belirleyin, '
          'isterseniz biyometriyi etkinleştirin. Uygulama açılırken istenir.\n'
          '• Belirli bir notu kilitleyin: not seçeneklerinden (uzun basın) → Kilitle.\n'
          '• Gizli bölüm: yalnızca kilit açıldıktan sonra görünen gizli notlar.\n'
          '• Parola notları ve kilitli notlar: ekran görüntüsü otomatik engellenir.',
      'es': 'Todos tus datos son locales y cifrados. Para mayor protección:\n\n'
          '• Bloqueo de la app: Ajustes → Seguridad y datos → Seguridad → activa el bloqueo y define un PIN, '
          'y activa la biometría si quieres. Se pide al abrir la app.\n'
          '• Bloquear una nota: en las opciones de la nota (mantén pulsado) → Bloquear.\n'
          '• Sección secreta: notas ocultas que solo aparecen tras desbloquear.\n'
          '• Notas de contraseñas y bloqueadas: las capturas se bloquean automáticamente.',
      'fa': 'همهٔ داده‌های شما محلی و رمزگذاری‌شده‌اند. برای حفاظت بیشتر:\n\n'
          '• قفل برنامه: تنظیمات ← امنیت و داده‌ها ← امنیت → قفل را فعال و یک رمز عددی تعیین کنید، '
          'و در صورت تمایل اثر انگشت/چهره را فعال کنید. هنگام باز کردن برنامه پرسیده می‌شود.\n'
          '• قفل یک یادداشت خاص: از گزینه‌های یادداشت (نگه دارید) → قفل.\n'
          '• بخش محرمانه: یادداشت‌های پنهان که فقط پس از باز کردن قفل دیده می‌شوند.\n'
          '• یادداشت‌های گذرواژه و قفل‌شده: اسکرین‌شات به‌طور خودکار مسدود می‌شود.',
      'id': 'Semua data Anda lokal dan terenkripsi. Untuk perlindungan ekstra:\n\n'
          '• Kunci aplikasi: Pengaturan → Keamanan & data → Keamanan → aktifkan kunci dan atur PIN, '
          'serta aktifkan biometrik bila mau. Diminta saat membuka aplikasi.\n'
          '• Kunci catatan tertentu: dari opsi catatan (tekan lama) → Kunci.\n'
          '• Bagian rahasia: catatan tersembunyi yang hanya muncul setelah dibuka.\n'
          '• Catatan kata sandi dan terkunci: tangkapan layar diblokir otomatis.',
      'fr': "Toutes vos données sont locales et chiffrées. Pour plus de protection :\n\n"
          "• Verrouillage de l'app : Réglages → Sécurité et données → Sécurité → activez le verrou et définissez un code, "
          "et activez la biométrie si vous le souhaitez. Demandé à l'ouverture de l'app.\n"
          "• Verrouiller une note précise : depuis les options de la note (appui long) → Verrouiller.\n"
          "• Section secrète : notes masquées qui n'apparaissent qu'après déverrouillage.\n"
          "• Notes de mots de passe et verrouillées : les captures d'écran sont bloquées automatiquement.",
      'de': 'Alle Ihre Daten sind lokal und verschlüsselt. Für zusätzlichen Schutz:\n\n'
          '• App-Sperre: Einstellungen → Sicherheit & Daten → Sicherheit → Sperre aktivieren und eine PIN festlegen, '
          'und bei Bedarf Biometrie aktivieren. Wird beim Öffnen der App abgefragt.\n'
          '• Eine bestimmte Notiz sperren: aus den Notizoptionen (lang drücken) → Sperren.\n'
          '• Geheimer Bereich: versteckte Notizen, die erst nach dem Entsperren erscheinen.\n'
          '• Passwort- und gesperrte Notizen: Screenshots werden automatisch blockiert.',
    },
  ),
  GuideTopic(
    'backup',
    Icons.backup_outlined,
    {
      'ar': 'النسخ الاحتياطي والاستعادة',
      'en': 'Backup & restore',
      'tr': 'Yedekleme ve geri yükleme',
      'es': 'Copia de seguridad y restauración',
      'fa': 'پشتیبان‌گیری و بازیابی',
      'id': 'Pencadangan & pemulihan',
      'fr': 'Sauvegarde et restauration',
      'de': 'Sicherung & Wiederherstellung',
    },
    {
      'ar': 'كل النسخ مشفّرة AES‑256 بكلمة مرور تحدّدها (دونها لا يمكن الاستعادة — احفظها!).\n\n'
          'افتح: الإعدادات ← الأمان والبيانات ← النسخ الاحتياطي.\n'
          '• نسخة تلقائية يومية: مفعّلة افتراضيًّا، تُحفظ داخل الجهاز (٧ خانات أسبوعيّة).\n'
          '• تصدير نسخة: تحفظ ملفًّا مشفّرًا في الجهاز.\n'
          '• مشاركة للسحابة: أرسل النسخة لأي تطبيق (Drive/تيليجرام…).\n'
          '• الاستعادة: «استعادة من نسخة» — مع لقطة أمان تتيح التراجع بضغطة.\n\n'
          '💡 النسخة الداخلية تُحذف عند إلغاء التثبيت — خذ نسخة خارجية (تصدير/مشاركة) دوريًّا.',
      'en': 'All backups are AES‑256 encrypted with a password you set (without it they cannot be restored — keep it!).\n\n'
          'Open: Settings → Security & data → Backup.\n'
          '• Daily auto-backup: on by default, stored on the device (7 weekly slots).\n'
          '• Export backup: saves an encrypted file to the device.\n'
          '• Share to cloud: send the backup to any app (Drive/Telegram…).\n'
          '• Restore: “Restore from backup” — with a safety snapshot so you can undo with one tap.\n\n'
          '💡 The internal backup is removed on uninstall — take an external backup (export/share) regularly.',
      'tr': 'Tüm yedekler, belirlediğiniz bir parolayla AES‑256 ile şifrelenir (parola olmadan geri yüklenemez — saklayın!).\n\n'
          'Açın: Ayarlar → Güvenlik ve veriler → Yedekleme.\n'
          '• Günlük otomatik yedek: varsayılan açık, cihazda saklanır (7 haftalık slot).\n'
          '• Yedeği dışa aktar: cihaza şifreli bir dosya kaydeder.\n'
          '• Buluta paylaş: yedeği herhangi bir uygulamaya gönderin (Drive/Telegram…).\n'
          '• Geri yükle: “Yedekten geri yükle” — geri almayı sağlayan güvenlik anlık görüntüsüyle.\n\n'
          '💡 İç yedek, kaldırmada silinir — düzenli olarak harici yedek (dışa aktar/paylaş) alın.',
      'es': 'Todas las copias se cifran con AES‑256 con una contraseña que tú defines (sin ella no se pueden restaurar — ¡guárdala!).\n\n'
          'Abre: Ajustes → Seguridad y datos → Copia de seguridad.\n'
          '• Copia automática diaria: activada por defecto, guardada en el dispositivo (7 ranuras semanales).\n'
          '• Exportar copia: guarda un archivo cifrado en el dispositivo.\n'
          '• Compartir a la nube: envía la copia a cualquier app (Drive/Telegram…).\n'
          '• Restaurar: “Restaurar desde copia” — con una instantánea de seguridad para deshacer con un toque.\n\n'
          '💡 La copia interna se borra al desinstalar — haz una copia externa (exportar/compartir) con regularidad.',
      'fa': 'همهٔ پشتیبان‌ها با AES‑256 و گذرواژه‌ای که تعیین می‌کنید رمزگذاری می‌شوند (بدون آن بازیابی ممکن نیست — نگه دارید!).\n\n'
          'باز کنید: تنظیمات ← امنیت و داده‌ها ← پشتیبان‌گیری.\n'
          '• پشتیبان خودکار روزانه: به‌طور پیش‌فرض فعال، روی دستگاه ذخیره می‌شود (۷ خانهٔ هفتگی).\n'
          '• خروجی پشتیبان: یک فایل رمزگذاری‌شده روی دستگاه ذخیره می‌کند.\n'
          '• اشتراک در ابر: پشتیبان را به هر برنامه‌ای بفرستید (Drive/تلگرام…).\n'
          '• بازیابی: «بازیابی از پشتیبان» — همراه با عکس ایمنی برای بازگرداندن با یک لمس.\n\n'
          '💡 پشتیبان داخلی هنگام حذف برنامه پاک می‌شود — مرتب پشتیبان بیرونی (خروجی/اشتراک) بگیرید.',
      'id': 'Semua cadangan dienkripsi AES‑256 dengan kata sandi yang Anda tetapkan (tanpa itu tidak bisa dipulihkan — simpan!).\n\n'
          'Buka: Pengaturan → Keamanan & data → Pencadangan.\n'
          '• Cadangan otomatis harian: aktif bawaan, disimpan di perangkat (7 slot mingguan).\n'
          '• Ekspor cadangan: menyimpan berkas terenkripsi ke perangkat.\n'
          '• Bagikan ke cloud: kirim cadangan ke aplikasi mana pun (Drive/Telegram…).\n'
          '• Pulihkan: “Pulihkan dari cadangan” — dengan snapshot keamanan agar bisa dibatalkan sekali ketuk.\n\n'
          '💡 Cadangan internal terhapus saat dicopot — buat cadangan eksternal (ekspor/bagikan) secara berkala.',
      'fr': "Toutes les sauvegardes sont chiffrées en AES‑256 avec un mot de passe que vous définissez (sans lui, impossible de restaurer — conservez-le !).\n\n"
          "Ouvrez : Réglages → Sécurité et données → Sauvegarde.\n"
          "• Sauvegarde auto quotidienne : activée par défaut, stockée sur l'appareil (7 emplacements hebdo).\n"
          "• Exporter une sauvegarde : enregistre un fichier chiffré sur l'appareil.\n"
          "• Partager vers le cloud : envoyez la sauvegarde à n'importe quelle app (Drive/Telegram…).\n"
          "• Restaurer : « Restaurer depuis une sauvegarde » — avec un instantané de sécurité pour annuler en un geste.\n\n"
          "💡 La sauvegarde interne est supprimée à la désinstallation — faites une sauvegarde externe (export/partage) régulièrement.",
      'de': 'Alle Sicherungen sind mit AES‑256 und einem von Ihnen gewählten Passwort verschlüsselt (ohne es ist keine Wiederherstellung möglich — gut aufbewahren!).\n\n'
          'Öffnen: Einstellungen → Sicherheit & Daten → Sicherung.\n'
          '• Tägliche Auto-Sicherung: standardmäßig an, auf dem Gerät gespeichert (7 Wochen-Slots).\n'
          '• Sicherung exportieren: speichert eine verschlüsselte Datei auf dem Gerät.\n'
          '• In die Cloud teilen: Sicherung an eine beliebige App senden (Drive/Telegram…).\n'
          '• Wiederherstellen: „Aus Sicherung wiederherstellen“ — mit Sicherheits-Snapshot zum Rückgängigmachen per Tipp.\n\n'
          '💡 Die interne Sicherung wird bei Deinstallation entfernt — machen Sie regelmäßig eine externe Sicherung (Export/Teilen).',
    },
  ),
  GuideTopic(
    'sync',
    Icons.cloud_sync_outlined,
    {
      'ar': 'المزامنة السحابية (تهيئة خطوة بخطوة)',
      'en': 'Cloud sync (step-by-step setup)',
      'tr': 'Bulut eşitleme (adım adım kurulum)',
      'es': 'Sincronización en la nube (paso a paso)',
      'fa': 'همگام‌سازی ابری (راه‌اندازی گام‌به‌گام)',
      'id': 'Sinkronisasi cloud (langkah demi langkah)',
      'fr': 'Synchronisation cloud (étape par étape)',
      'de': 'Cloud-Sync (Schritt für Schritt)',
    },
    {
      'ar': 'مزامنة مشفّرة طرفيًّا (E2E): الخادم لا يقرأ ملاحظاتك. تُزامَن النصوص والقوائم '
          'والوسوم والتصنيفات (المرفقات تُحفظ عبر النسخة الكاملة).\n\n'
          'افتح: الإعدادات ← الأمان والبيانات ← النسخ الاحتياطي ← تبويب «المزامنة السحابية».\n\n'
          '— الأسهل WebDAV (بلا إعداد خارجيّ):\n'
          '١) اختر «WebDAV».\n'
          '٢) أدخل رابط المجلّد على خادمك (مثال Nextcloud: '
          'https://cloud.example.com/remote.php/dav/files/USER/Notes) واسم المستخدم وكلمة المرور.\n'
          '٣) أدخل «عبارة التشفير» نفسها على كل أجهزتك.\n'
          '٤) اضغط «اختبار الاتصال» ثم «مزامنة الآن».\n\n'
          '— Google Drive: يتطلّب إعدادًا لمرّة واحدة في Google Cloud (مشروع + تفعيل Drive API '
          '+ عميل OAuth أندرويد باسم الحزمة وبصمة SHA‑1 + إضافة بريدك كـ Test user).\n\n'
          '💡 ضع «عبارة التشفير» ذاتها على كل الأجهزة، وإلا تعذّر فكّ التشفير.',
      'en': 'End-to-end encrypted (E2E) sync: the server cannot read your notes. Text, checklists, '
          'tags and categories are synced (attachments are saved via the full backup).\n\n'
          'Open: Settings → Security & data → Backup → “Cloud sync” tab.\n\n'
          '— Easiest: WebDAV (no external setup):\n'
          '1) Choose “WebDAV”.\n'
          '2) Enter your server folder URL (Nextcloud example: '
          'https://cloud.example.com/remote.php/dav/files/USER/Notes), username and password.\n'
          '3) Enter the same “encryption passphrase” on all your devices.\n'
          '4) Tap “Test connection”, then “Sync now”.\n\n'
          '— Google Drive: requires a one-time setup in Google Cloud (a project + enable Drive API '
          '+ an Android OAuth client with the package name and SHA‑1 + add your email as a Test user).\n\n'
          '💡 Use the same passphrase on every device, otherwise decryption fails.',
      'tr': 'Uçtan uca şifreli (E2E) eşitleme: sunucu notlarınızı okuyamaz. Metin, listeler, '
          'etiketler ve kategoriler eşitlenir (ekler tam yedek ile saklanır).\n\n'
          'Açın: Ayarlar → Güvenlik ve veriler → Yedekleme → “Bulut eşitleme” sekmesi.\n\n'
          '— En kolayı: WebDAV (harici kurulum yok):\n'
          '1) “WebDAV” seçin.\n'
          '2) Sunucu klasör adresinizi (Nextcloud örneği: '
          'https://cloud.example.com/remote.php/dav/files/USER/Notes), kullanıcı adı ve parolayı girin.\n'
          '3) Tüm cihazlarınızda aynı “şifreleme parolasını” girin.\n'
          '4) “Bağlantıyı test et”e, sonra “Şimdi eşitle”ye dokunun.\n\n'
          '— Google Drive: Google Cloud’da tek seferlik kurulum gerektirir (proje + Drive API '
          '+ paket adı ve SHA‑1 ile Android OAuth istemcisi + e-postanızı Test kullanıcısı ekleme).\n\n'
          '💡 Her cihazda aynı parolayı kullanın, yoksa şifre çözme başarısız olur.',
      'es': 'Sincronización cifrada de extremo a extremo (E2E): el servidor no puede leer tus notas. '
          'Se sincronizan texto, listas, etiquetas y categorías (los adjuntos se guardan en la copia completa).\n\n'
          'Abre: Ajustes → Seguridad y datos → Copia de seguridad → pestaña “Sincronización en la nube”.\n\n'
          '— Lo más fácil: WebDAV (sin configuración externa):\n'
          '1) Elige “WebDAV”.\n'
          '2) Introduce la URL de la carpeta de tu servidor (ejemplo Nextcloud: '
          'https://cloud.example.com/remote.php/dav/files/USER/Notes), usuario y contraseña.\n'
          '3) Introduce la misma “frase de cifrado” en todos tus dispositivos.\n'
          '4) Toca “Probar conexión” y luego “Sincronizar ahora”.\n\n'
          '— Google Drive: requiere configuración única en Google Cloud (proyecto + activar Drive API '
          '+ cliente OAuth de Android con el nombre del paquete y el SHA‑1 + añadir tu correo como usuario de prueba).\n\n'
          '💡 Usa la misma frase en todos los dispositivos, o el descifrado fallará.',
      'fa': 'همگام‌سازی رمزگذاری سرتاسری (E2E): سرور نمی‌تواند یادداشت‌های شما را بخواند. متن، فهرست‌ها، '
          'برچسب‌ها و دسته‌ها همگام می‌شوند (پیوست‌ها از طریق پشتیبان کامل ذخیره می‌شوند).\n\n'
          'باز کنید: تنظیمات ← امنیت و داده‌ها ← پشتیبان‌گیری ← زبانهٔ «همگام‌سازی ابری».\n\n'
          '— ساده‌ترین: WebDAV (بدون تنظیم بیرونی):\n'
          '۱) «WebDAV» را انتخاب کنید.\n'
          '۲) نشانی پوشهٔ سرور خود (نمونهٔ Nextcloud: '
          'https://cloud.example.com/remote.php/dav/files/USER/Notes)، نام کاربری و گذرواژه را وارد کنید.\n'
          '۳) همان «عبارت رمزگذاری» را روی همهٔ دستگاه‌ها وارد کنید.\n'
          '۴) «آزمایش اتصال» سپس «همگام‌سازی اکنون» را بزنید.\n\n'
          '— Google Drive: یک‌بار تنظیم در Google Cloud لازم دارد (پروژه + فعال‌سازی Drive API '
          '+ کلاینت OAuth اندروید با نام بسته و SHA‑1 + افزودن ایمیلتان به‌عنوان Test user).\n\n'
          '💡 روی همهٔ دستگاه‌ها همان عبارت را استفاده کنید، وگرنه رمزگشایی شکست می‌خورد.',
      'id': 'Sinkronisasi terenkripsi ujung-ke-ujung (E2E): server tidak bisa membaca catatan Anda. Teks, daftar, '
          'tag, dan kategori disinkronkan (lampiran disimpan via cadangan penuh).\n\n'
          'Buka: Pengaturan → Keamanan & data → Pencadangan → tab “Sinkronisasi cloud”.\n\n'
          '— Termudah: WebDAV (tanpa setup eksternal):\n'
          '1) Pilih “WebDAV”.\n'
          '2) Masukkan URL folder server Anda (contoh Nextcloud: '
          'https://cloud.example.com/remote.php/dav/files/USER/Notes), nama pengguna, dan kata sandi.\n'
          '3) Masukkan “frasa enkripsi” yang sama di semua perangkat.\n'
          '4) Ketuk “Tes koneksi”, lalu “Sinkronkan sekarang”.\n\n'
          '— Google Drive: perlu setup sekali di Google Cloud (proyek + aktifkan Drive API '
          '+ klien OAuth Android dengan nama paket dan SHA‑1 + tambahkan email Anda sebagai Test user).\n\n'
          '💡 Gunakan frasa yang sama di setiap perangkat, jika tidak dekripsi gagal.',
      'fr': "Synchronisation chiffrée de bout en bout (E2E) : le serveur ne peut pas lire vos notes. "
          "Le texte, les listes, les tags et les catégories sont synchronisés (les pièces jointes via la sauvegarde complète).\n\n"
          "Ouvrez : Réglages → Sécurité et données → Sauvegarde → onglet « Synchronisation cloud ».\n\n"
          "— Le plus simple : WebDAV (sans configuration externe) :\n"
          "1) Choisissez « WebDAV ».\n"
          "2) Saisissez l'URL du dossier de votre serveur (exemple Nextcloud : "
          "https://cloud.example.com/remote.php/dav/files/USER/Notes), le nom d'utilisateur et le mot de passe.\n"
          "3) Saisissez la même « phrase de chiffrement » sur tous vos appareils.\n"
          "4) Touchez « Tester la connexion », puis « Synchroniser ».\n\n"
          "— Google Drive : nécessite une configuration unique dans Google Cloud (un projet + activer Drive API "
          "+ un client OAuth Android avec le nom du paquet et le SHA‑1 + ajouter votre e-mail comme utilisateur de test).\n\n"
          "💡 Utilisez la même phrase sur chaque appareil, sinon le déchiffrement échoue.",
      'de': 'Ende-zu-Ende verschlüsselte (E2E) Synchronisierung: der Server kann Ihre Notizen nicht lesen. Text, Listen, '
          'Tags und Kategorien werden synchronisiert (Anhänge über die vollständige Sicherung).\n\n'
          'Öffnen: Einstellungen → Sicherheit & Daten → Sicherung → Tab „Cloud-Sync“.\n\n'
          '— Am einfachsten: WebDAV (keine externe Einrichtung):\n'
          '1) „WebDAV“ wählen.\n'
          '2) Die Ordner-URL Ihres Servers (Nextcloud-Beispiel: '
          'https://cloud.example.com/remote.php/dav/files/USER/Notes), Benutzername und Passwort eingeben.\n'
          '3) Dieselbe „Verschlüsselungs-Passphrase“ auf allen Geräten eingeben.\n'
          '4) „Verbindung testen“, dann „Jetzt synchronisieren“ tippen.\n\n'
          '— Google Drive: erfordert eine einmalige Einrichtung in Google Cloud (Projekt + Drive API aktivieren '
          '+ Android-OAuth-Client mit Paketname und SHA‑1 + Ihre E-Mail als Testnutzer hinzufügen).\n\n'
          '💡 Verwenden Sie auf jedem Gerät dieselbe Passphrase, sonst schlägt die Entschlüsselung fehl.',
    },
  ),
  GuideTopic(
    'tools',
    Icons.widgets_outlined,
    {
      'ar': 'أدوات إضافية',
      'en': 'Extra tools',
      'tr': 'Ek araçlar',
      'es': 'Herramientas extra',
      'fa': 'ابزارهای بیشتر',
      'id': 'Alat tambahan',
      'fr': 'Outils supplémentaires',
      'de': 'Weitere Werkzeuge',
    },
    {
      'ar': '• ويدجت الشاشة الرئيسية: أضِف ويدجت «ملاحظات» لشاشة هاتفك.\n'
          '• تثبيت في الإشعارات: من خيارات الملاحظة — تبقى كإشعار صامت مستمرّ.\n'
          '• مشاركة كصورة / تصدير PDF / تصدير Word لأي ملاحظة.\n'
          '• الكتابة الصوتية: زرّ الميكروفون في المحرّر يحوّل صوتك إلى نصّ.\n'
          '• الملخّص الأسبوعي والتنظيف: من القائمة الجانبية.',
      'en': '• Home-screen widget: add the Notes widget to your phone’s home screen.\n'
          '• Pin to notifications: from the note options — stays as a silent ongoing notification.\n'
          '• Share as image / export PDF / export Word for any note.\n'
          '• Voice typing: the mic button in the editor turns speech into text.\n'
          '• Weekly summary and Clean-up: from the side menu.',
      'tr': '• Ana ekran widget’ı: telefonunuzun ana ekranına Notlar widget’ını ekleyin.\n'
          '• Bildirimlere sabitle: not seçeneklerinden — sessiz kalıcı bir bildirim olarak kalır.\n'
          '• Görsel olarak paylaş / PDF / Word dışa aktar.\n'
          '• Sesle yazma: düzenleyicideki mikrofon düğmesi konuşmayı metne çevirir.\n'
          '• Haftalık özet ve Temizlik: yan menüden.',
      'es': '• Widget de pantalla de inicio: añade el widget de Notas a tu pantalla.\n'
          '• Fijar en notificaciones: desde las opciones de la nota — notificación silenciosa.\n'
          '• Compartir como imagen / exportar PDF / Word.\n'
          '• Dictado por voz: el botón del micrófono convierte voz en texto.\n'
          '• Resumen semanal y Limpieza: desde el menú lateral.',
      'fa': '• ویجت صفحهٔ اصلی: ویجت «یادداشت‌ها» را به صفحهٔ گوشی بیفزایید.\n'
          '• سنجاق در اعلان‌ها: از گزینه‌های یادداشت — به‌صورت اعلان بی‌صدای دائمی می‌ماند.\n'
          '• اشتراک به‌صورت تصویر / خروجی PDF / Word.\n'
          '• نوشتن صوتی: دکمهٔ میکروفون در ویرایشگر، گفتار را به متن تبدیل می‌کند.\n'
          '• خلاصهٔ هفتگی و پاک‌سازی: از منوی کناری.',
      'id': '• Widget layar utama: tambahkan widget Notes ke layar ponsel.\n'
          '• Sematkan ke notifikasi: dari opsi catatan — tetap sebagai notifikasi senyap.\n'
          '• Bagikan sebagai gambar / ekspor PDF / Word.\n'
          '• Ketik suara: tombol mikrofon di editor mengubah suara jadi teks.\n'
          '• Ringkasan mingguan dan Pembersihan: dari menu samping.',
      'fr': "• Widget d'écran d'accueil : ajoutez le widget Notes à votre écran.\n"
          "• Épingler aux notifications : depuis les options de la note — notification silencieuse persistante.\n"
          "• Partager en image / exporter en PDF / Word.\n"
          "• Saisie vocale : le bouton micro de l'éditeur transforme la voix en texte.\n"
          "• Résumé hebdomadaire et Nettoyage : depuis le menu latéral.",
      'de': '• Startbildschirm-Widget: fügen Sie das Notes-Widget hinzu.\n'
          '• An Benachrichtigungen anheften: aus den Notizoptionen — bleibt als stille Dauerbenachrichtigung.\n'
          '• Als Bild teilen / als PDF / Word exportieren.\n'
          '• Spracheingabe: die Mikrofon-Schaltfläche im Editor wandelt Sprache in Text um.\n'
          '• Wochenübersicht und Bereinigung: aus dem Seitenmenü.',
    },
  ),
  GuideTopic(
    'settings',
    Icons.settings_outlined,
    {
      'ar': 'الإعدادات والمظهر واللغة',
      'en': 'Settings, appearance & language',
      'tr': 'Ayarlar, görünüm ve dil',
      'es': 'Ajustes, apariencia e idioma',
      'fa': 'تنظیمات، ظاهر و زبان',
      'id': 'Pengaturan, tampilan & bahasa',
      'fr': 'Réglages, apparence et langue',
      'de': 'Einstellungen, Aussehen & Sprache',
    },
    {
      'ar': 'الإعدادات مقسّمة لأقسام واضحة:\n\n'
          '• التخصيص ← المظهر واللغة: غيّر اللغة (أوّل خيار)، الوضع (نهاري/ليلي/النظام)، '
          'لون السمة (١٨ لونًا)، حجم الخط ونوعه.\n'
          '• الملاحظات والمحرّر: الملاحظة الافتراضية، تسطير الصفحة، أزرار شريط التنسيق.\n'
          '• الأمان والبيانات: القفل، النسخ، المزامنة، التنظيم.\n'
          '• عن التطبيق: الإصدار والتحديث.',
      'en': 'Settings are split into clear sections:\n\n'
          '• Personalize → Appearance & language: change the language (first option), mode '
          '(light/dark/system), theme color (18 colors), font size and family.\n'
          '• Notes & editor: default note, page ruling, toolbar buttons.\n'
          '• Security & data: lock, backup, sync, organization.\n'
          '• About: version and updates.',
      'tr': 'Ayarlar net bölümlere ayrılmıştır:\n\n'
          '• Kişiselleştirme → Görünüm ve dil: dili değiştirin (ilk seçenek), mod '
          '(açık/koyu/sistem), tema rengi (18 renk), yazı tipi boyutu ve ailesi.\n'
          '• Notlar ve düzenleyici: varsayılan not, sayfa çizgileri, araç çubuğu düğmeleri.\n'
          '• Güvenlik ve veriler: kilit, yedekleme, eşitleme, düzenleme.\n'
          '• Hakkında: sürüm ve güncellemeler.',
      'es': 'Los ajustes se dividen en secciones claras:\n\n'
          '• Personalizar → Apariencia e idioma: cambia el idioma (primera opción), modo '
          '(claro/oscuro/sistema), color del tema (18 colores), tamaño y tipo de letra.\n'
          '• Notas y editor: nota predeterminada, líneas de página, botones de la barra.\n'
          '• Seguridad y datos: bloqueo, copia, sincronización, organización.\n'
          '• Acerca de: versión y actualizaciones.',
      'fa': 'تنظیمات به بخش‌های روشن تقسیم شده است:\n\n'
          '• شخصی‌سازی ← ظاهر و زبان: زبان (اولین گزینه)، حالت '
          '(روشن/تیره/سیستم)، رنگ پوسته (۱۸ رنگ)، اندازه و نوع فونت.\n'
          '• یادداشت‌ها و ویرایشگر: یادداشت پیش‌فرض، خط‌کشی صفحه، دکمه‌های نوار ابزار.\n'
          '• امنیت و داده‌ها: قفل، پشتیبان، همگام‌سازی، سازمان‌دهی.\n'
          '• درباره: نسخه و به‌روزرسانی.',
      'id': 'Pengaturan dibagi ke bagian yang jelas:\n\n'
          '• Personalisasi → Tampilan & bahasa: ubah bahasa (opsi pertama), mode '
          '(terang/gelap/sistem), warna tema (18 warna), ukuran dan jenis font.\n'
          '• Catatan & editor: catatan bawaan, garis halaman, tombol bilah alat.\n'
          '• Keamanan & data: kunci, cadangan, sinkronisasi, pengaturan.\n'
          '• Tentang: versi dan pembaruan.',
      'fr': "Les réglages sont divisés en sections claires :\n\n"
          "• Personnaliser → Apparence et langue : changez la langue (première option), le mode "
          "(clair/sombre/système), la couleur du thème (18 couleurs), la taille et la police.\n"
          "• Notes et éditeur : note par défaut, lignes de page, boutons de la barre.\n"
          "• Sécurité et données : verrou, sauvegarde, synchro, organisation.\n"
          "• À propos : version et mises à jour.",
      'de': 'Die Einstellungen sind in klare Bereiche unterteilt:\n\n'
          '• Personalisieren → Aussehen & Sprache: Sprache (erste Option), Modus '
          '(hell/dunkel/System), Themenfarbe (18 Farben), Schriftgröße und -art.\n'
          '• Notizen & Editor: Standardnotiz, Seitenlinien, Symbolleisten-Schaltflächen.\n'
          '• Sicherheit & Daten: Sperre, Sicherung, Sync, Organisation.\n'
          '• Über: Version und Updates.',
    },
  ),
  GuideTopic(
    'requirements',
    Icons.phonelink_setup_outlined,
    {
      'ar': 'متطلبات التطبيق على الجهاز',
      'en': 'Device requirements',
      'tr': 'Cihaz gereksinimleri',
      'es': 'Requisitos del dispositivo',
      'fa': 'نیازمندی‌های دستگاه',
      'id': 'Persyaratan perangkat',
      'fr': "Configuration requise",
      'de': 'Geräteanforderungen',
    },
    {
      'ar': 'يعمل التطبيق على معظم أجهزة أندرويد:\n\n'
          '• نظام التشغيل: أندرويد 8.0 (API 26) أو أحدث.\n'
          '• المعمارية: arm64‑v8a (الأغلب)، armeabi‑v7a (أجهزة قديمة)، أو x86_64. '
          'النسخة «الشاملة» تعمل على الكلّ.\n'
          '• الذاكرة: يُفضّل 2 غيغابايت RAM فأكثر.\n'
          '• التخزين: ~120 ميغابايت للنسخة الشاملة (أو ~55 ميغابايت لنسخة arm64).\n'
          '• يعمل دون خدمات Google Play (يناسب أجهزة هواوي/AOSP): WebDAV وكل الميزات '
          'الأساسية تعمل بدونها، ومزامنة Google Drive وحدها تحتاجها.\n'
          '• أذونات اختيارية حسب الميزة: الميكروفون (صوت)، البصمة (قفل)، الإشعارات '
          '(تثبيت ملاحظة)، الكاميرا (صور)، الإنترنت (مزامنة/تحديث).\n'
          '• يعمل على الهواتف والأجهزة اللوحية، أفقيًّا وعموديًّا.',
      'en': 'The app runs on most Android devices:\n\n'
          '• OS: Android 8.0 (API 26) or newer.\n'
          '• Architecture: arm64‑v8a (most phones), armeabi‑v7a (older devices), or x86_64. '
          'The “universal” build runs on all of them.\n'
          '• Memory: 2 GB RAM or more recommended.\n'
          '• Storage: ~120 MB for the universal build (or ~55 MB for the arm64 build).\n'
          '• Works without Google Play Services (good for Huawei/AOSP): WebDAV and all core '
          'features work without them; only Google Drive sync needs them.\n'
          '• Optional permissions per feature: microphone (voice), biometrics (lock), '
          'notifications (pin a note), camera (images), internet (sync/update).\n'
          '• Works on phones and tablets, in portrait and landscape.',
    },
  ),
  GuideTopic(
    'privacy',
    Icons.privacy_tip_outlined,
    {
      'ar': 'الخصوصية والاستخدام',
      'en': 'Privacy & usage',
      'tr': 'Gizlilik ve kullanım',
      'es': 'Privacidad y uso',
      'fa': 'حریم خصوصی و استفاده',
      'id': 'Privasi & penggunaan',
      'fr': "Confidentialité et usage",
      'de': 'Datenschutz & Nutzung',
    },
    {
      'ar': 'سياسة الخصوصية والاستخدام:\n\n'
          '• بياناتك ملكك: كل ملاحظاتك تُخزَّن محليًّا على جهازك في قاعدة بيانات مشفّرة '
          '(SQLCipher). لا يوجد خادم لنا ولا نرى بياناتك.\n'
          '• لا حسابات، ولا تتبّع، ولا إعلانات، ولا تحليلات.\n'
          '• الإنترنت اختياريّ: يُستخدم فقط إن فعّلت المزامنة السحابية (مشفّرة طرفيًّا '
          'E2E) أو التحديث الذاتيّ.\n'
          '• الأذونات تُطلب عند الحاجة فقط، ولكلٍّ غرض واضح (صوت/بصمة/إشعارات/تثبيت تحديث).\n'
          '• الاستخدام السليم: التطبيق للاستخدام الشخصيّ المشروع. أنت مسؤول عن محتوى '
          'ملاحظاتك، وعن أخذ نسخ احتياطية منتظمة، وعن حفظ كلمات المرور وعبارات التشفير.',
      'en': 'Privacy & usage policy:\n\n'
          '• Your data is yours: all notes are stored locally on your device in an encrypted '
          'database (SQLCipher). We run no server and never see your data.\n'
          '• No accounts, no tracking, no ads, no analytics.\n'
          '• Internet is optional: used only if you enable cloud sync (end-to-end encrypted) '
          'or self-update.\n'
          '• Permissions are requested only when needed, each with a clear purpose '
          '(voice/biometrics/notifications/update install).\n'
          '• Proper use: the app is for lawful personal use. You are responsible for your '
          'notes’ content, for taking regular backups, and for keeping your passwords and '
          'encryption passphrases.',
      'tr': 'Gizlilik ve kullanım politikası:\n\n'
          '• Verileriniz size aittir: tüm notlar cihazınızda şifreli bir veritabanında '
          '(SQLCipher) yerel olarak saklanır. Sunucumuz yoktur ve verilerinizi asla görmeyiz.\n'
          '• Hesap yok, takip yok, reklam yok, analiz yok.\n'
          '• İnternet isteğe bağlıdır: yalnızca bulut eşitlemeyi (uçtan uca şifreli) veya '
          'kendi kendine güncellemeyi açarsanız kullanılır.\n'
          '• İzinler yalnızca gerektiğinde ve net bir amaçla istenir.\n'
          '• Doğru kullanım: uygulama yasal kişisel kullanım içindir. Notlarınızın içeriğinden, '
          'düzenli yedek almaktan ve parolalarınızı/şifreleme ifadelerinizi saklamaktan siz sorumlusunuz.',
      'es': 'Política de privacidad y uso:\n\n'
          '• Tus datos son tuyos: todas las notas se guardan localmente en tu dispositivo en una '
          'base de datos cifrada (SQLCipher). No tenemos servidor y nunca vemos tus datos.\n'
          '• Sin cuentas, sin rastreo, sin anuncios, sin analíticas.\n'
          '• Internet es opcional: se usa solo si activas la sincronización en la nube (cifrada de '
          'extremo a extremo) o la autoactualización.\n'
          '• Los permisos se piden solo cuando se necesitan, cada uno con un propósito claro.\n'
          '• Uso correcto: la app es para uso personal lícito. Eres responsable del contenido de tus '
          'notas, de hacer copias periódicas y de guardar tus contraseñas y frases de cifrado.',
      'fa': 'سیاست حریم خصوصی و استفاده:\n\n'
          '• داده‌های شما مال شماست: همهٔ یادداشت‌ها به‌صورت محلی روی دستگاه شما در پایگاه‌دادهٔ '
          'رمزگذاری‌شده (SQLCipher) ذخیره می‌شوند. ما سروری نداریم و هرگز داده‌های شما را نمی‌بینیم.\n'
          '• بدون حساب، بدون ردیابی، بدون تبلیغات، بدون تحلیل.\n'
          '• اینترنت اختیاری است: فقط اگر همگام‌سازی ابری (رمزگذاری سرتاسری) یا به‌روزرسانی خودکار '
          'را فعال کنید استفاده می‌شود.\n'
          '• مجوزها فقط هنگام نیاز و با هدف روشن درخواست می‌شوند.\n'
          '• استفادهٔ درست: برنامه برای استفادهٔ شخصی قانونی است. شما مسئول محتوای یادداشت‌ها، '
          'گرفتن پشتیبان منظم و نگه‌داری گذرواژه‌ها و عبارات رمزگذاری هستید.',
      'id': 'Kebijakan privasi & penggunaan:\n\n'
          '• Data Anda milik Anda: semua catatan disimpan secara lokal di perangkat Anda dalam basis '
          'data terenkripsi (SQLCipher). Kami tidak punya server dan tidak pernah melihat data Anda.\n'
          '• Tanpa akun, tanpa pelacakan, tanpa iklan, tanpa analitik.\n'
          '• Internet opsional: dipakai hanya jika Anda mengaktifkan sinkronisasi cloud (terenkripsi '
          'ujung-ke-ujung) atau pembaruan otomatis.\n'
          '• Izin diminta hanya saat diperlukan, masing-masing dengan tujuan jelas.\n'
          '• Penggunaan yang benar: aplikasi untuk penggunaan pribadi yang sah. Anda bertanggung jawab '
          'atas isi catatan, membuat cadangan berkala, dan menyimpan kata sandi serta frasa enkripsi.',
      'fr': "Politique de confidentialité et d'usage :\n\n"
          "• Vos données vous appartiennent : toutes les notes sont stockées localement sur votre "
          "appareil dans une base de données chiffrée (SQLCipher). Nous n'avons aucun serveur et ne "
          "voyons jamais vos données.\n"
          "• Pas de comptes, pas de suivi, pas de publicité, pas d'analyse.\n"
          "• Internet est optionnel : utilisé uniquement si vous activez la synchronisation cloud "
          "(chiffrée de bout en bout) ou la mise à jour automatique.\n"
          "• Les autorisations sont demandées seulement quand c'est nécessaire, avec un but clair.\n"
          "• Usage correct : l'app est destinée à un usage personnel licite. Vous êtes responsable du "
          "contenu de vos notes, des sauvegardes régulières et de vos mots de passe et phrases de chiffrement.",
      'de': 'Datenschutz- & Nutzungsrichtlinie:\n\n'
          '• Ihre Daten gehören Ihnen: alle Notizen werden lokal auf Ihrem Gerät in einer '
          'verschlüsselten Datenbank (SQLCipher) gespeichert. Wir betreiben keinen Server und sehen '
          'Ihre Daten nie.\n'
          '• Keine Konten, kein Tracking, keine Werbung, keine Analyse.\n'
          '• Internet ist optional: wird nur genutzt, wenn Sie Cloud-Sync (Ende-zu-Ende verschlüsselt) '
          'oder Selbst-Update aktivieren.\n'
          '• Berechtigungen werden nur bei Bedarf und mit klarem Zweck angefragt.\n'
          '• Richtige Nutzung: die App ist für rechtmäßige persönliche Nutzung. Sie sind '
          'verantwortlich für den Inhalt Ihrer Notizen, regelmäßige Sicherungen und das Aufbewahren '
          'Ihrer Passwörter und Verschlüsselungs-Passphrasen.',
    },
  ),
  GuideTopic(
    'disclaimer',
    Icons.gavel_outlined,
    {
      'ar': 'إخلاء المسؤولية',
      'en': 'Disclaimer',
      'tr': 'Sorumluluk reddi',
      'es': 'Descargo de responsabilidad',
      'fa': 'سلب مسئولیت',
      'id': 'Penafian',
      'fr': "Avis de non-responsabilité",
      'de': 'Haftungsausschluss',
    },
    {
      'ar': 'إخلاء المسؤولية:\n\n'
          '• يُقدَّم التطبيق «كما هو» دون أي ضمان صريح أو ضمنيّ.\n'
          '• لا يتحمّل المطوّر أي مسؤولية عن أي خلل أو خطأ برمجيّ أو فقدان بيانات أو '
          'أضرار مباشرة أو غير مباشرة ناتجة عن استخدام التطبيق.\n'
          '• أنت وحدك مسؤول عن أخذ نُسخ احتياطية منتظمة وحفظ كلمات المرور؛ فقدان كلمة '
          'مرور النسخة يعني تعذّر استعادتها نهائيًّا.\n'
          '• لا يتحمّل المطوّر مسؤولية أي سوء استخدام للتطبيق أو استخدامه في أغراض مخالفة '
          'للأنظمة والقوانين؛ تقع هذه المسؤولية على عاتق المستخدم وحده.\n'
          '• باستخدامك التطبيق فإنك تقرّ بقبول هذه الشروط.',
      'en': 'Disclaimer:\n\n'
          '• The app is provided “as is”, without any warranty, express or implied.\n'
          '• The developer is not liable for any defect, software error, data loss, or any '
          'direct or indirect damages arising from using the app.\n'
          '• You alone are responsible for taking regular backups and keeping your passwords; '
          'losing the backup password means it can never be restored.\n'
          '• The developer is not responsible for any misuse of the app or its use for purposes '
          'that violate applicable laws and regulations; that responsibility rests solely with the user.\n'
          '• By using the app, you acknowledge and accept these terms.',
      'tr': 'Sorumluluk reddi:\n\n'
          '• Uygulama, açık veya zımni hiçbir garanti olmaksızın “olduğu gibi” sunulur.\n'
          '• Geliştirici; herhangi bir kusur, yazılım hatası, veri kaybı veya uygulamanın '
          'kullanımından doğan doğrudan ya da dolaylı zararlardan sorumlu değildir.\n'
          '• Düzenli yedek almak ve parolalarınızı saklamak yalnızca sizin sorumluluğunuzdadır; '
          'yedek parolasını kaybetmek, geri yüklemenin asla mümkün olmaması demektir.\n'
          '• Geliştirici, uygulamanın kötüye kullanımından veya yasalara aykırı amaçlarla '
          'kullanılmasından sorumlu değildir; bu sorumluluk yalnızca kullanıcıya aittir.\n'
          '• Uygulamayı kullanarak bu şartları kabul etmiş olursunuz.',
      'es': 'Descargo de responsabilidad:\n\n'
          '• La app se ofrece “tal cual”, sin garantía alguna, expresa o implícita.\n'
          '• El desarrollador no se hace responsable de ningún defecto, error de software, pérdida de '
          'datos ni de daños directos o indirectos derivados del uso de la app.\n'
          '• Solo tú eres responsable de hacer copias periódicas y de guardar tus contraseñas; perder '
          'la contraseña de la copia significa que nunca podrá restaurarse.\n'
          '• El desarrollador no es responsable del uso indebido de la app ni de su uso para fines que '
          'infrinjan las leyes; esa responsabilidad recae únicamente en el usuario.\n'
          '• Al usar la app, aceptas estos términos.',
      'fa': 'سلب مسئولیت:\n\n'
          '• برنامه «همان‌گونه که هست» و بدون هیچ ضمانت صریح یا ضمنی ارائه می‌شود.\n'
          '• توسعه‌دهنده هیچ مسئولیتی در قبال هر نقص، خطای نرم‌افزاری، از دست رفتن داده، یا خسارات '
          'مستقیم یا غیرمستقیم ناشی از استفاده از برنامه ندارد.\n'
          '• تنها شما مسئول گرفتن پشتیبان منظم و نگه‌داری گذرواژه‌ها هستید؛ از دست دادن گذرواژهٔ '
          'پشتیبان یعنی بازیابی هرگز ممکن نیست.\n'
          '• توسعه‌دهنده مسئول هیچ‌گونه سوءاستفاده از برنامه یا استفادهٔ آن برای اهداف مغایر قوانین '
          'نیست؛ این مسئولیت تنها بر عهدهٔ کاربر است.\n'
          '• با استفاده از برنامه، این شرایط را می‌پذیرید.',
      'id': 'Penafian:\n\n'
          '• Aplikasi disediakan “sebagaimana adanya”, tanpa jaminan apa pun, tersurat maupun tersirat.\n'
          '• Pengembang tidak bertanggung jawab atas cacat, kesalahan perangkat lunak, kehilangan data, '
          'atau kerugian langsung maupun tidak langsung akibat penggunaan aplikasi.\n'
          '• Hanya Anda yang bertanggung jawab membuat cadangan berkala dan menyimpan kata sandi; '
          'kehilangan kata sandi cadangan berarti tidak akan pernah bisa dipulihkan.\n'
          '• Pengembang tidak bertanggung jawab atas penyalahgunaan aplikasi atau penggunaannya untuk '
          'tujuan yang melanggar hukum; tanggung jawab itu sepenuhnya ada pada pengguna.\n'
          '• Dengan menggunakan aplikasi, Anda menerima ketentuan ini.',
      'fr': "Avis de non-responsabilité :\n\n"
          "• L'application est fournie « telle quelle », sans aucune garantie, expresse ou implicite.\n"
          "• Le développeur n'est pas responsable des défauts, erreurs logicielles, pertes de données, "
          "ni des dommages directs ou indirects résultant de l'utilisation de l'application.\n"
          "• Vous êtes seul responsable des sauvegardes régulières et de la conservation de vos mots de "
          "passe ; perdre le mot de passe de la sauvegarde signifie qu'elle ne pourra jamais être restaurée.\n"
          "• Le développeur n'est pas responsable d'un usage abusif de l'application ou de son "
          "utilisation à des fins illégales ; cette responsabilité incombe uniquement à l'utilisateur.\n"
          "• En utilisant l'application, vous acceptez ces conditions.",
      'de': 'Haftungsausschluss:\n\n'
          '• Die App wird „wie besehen“ bereitgestellt, ohne jegliche ausdrückliche oder '
          'stillschweigende Gewährleistung.\n'
          '• Der Entwickler haftet nicht für Mängel, Softwarefehler, Datenverlust oder direkte bzw. '
          'indirekte Schäden, die aus der Nutzung der App entstehen.\n'
          '• Allein Sie sind verantwortlich für regelmäßige Sicherungen und das Aufbewahren Ihrer '
          'Passwörter; der Verlust des Sicherungspassworts bedeutet, dass es nie wiederhergestellt werden kann.\n'
          '• Der Entwickler haftet nicht für Missbrauch der App oder deren Nutzung zu rechtswidrigen '
          'Zwecken; diese Verantwortung liegt allein beim Nutzer.\n'
          '• Durch die Nutzung der App akzeptieren Sie diese Bedingungen.',
    },
  ),
  GuideTopic(
    'faq',
    Icons.help_outline,
    {
      'ar': 'أسئلة شائعة',
      'en': 'FAQ',
      'tr': 'Sık sorulan sorular',
      'es': 'Preguntas frecuentes',
      'fa': 'پرسش‌های پرتکرار',
      'id': 'Tanya jawab',
      'fr': 'Questions fréquentes',
      'de': 'Häufige Fragen',
    },
    {
      'ar': '• هل بياناتي آمنة؟ نعم — محليّة ومشفّرة، ولا تُرفع إلا إن فعّلت المزامنة بنفسك.\n'
          '• نسيت كلمة مرور النسخة؟ لا يمكن استعادتها — احفظها في مكان آمن.\n'
          '• انتقلت لهاتف جديد؟ خذ نسخة خارجية من القديم واستوردها في الجديد (أو فعّل المزامنة).\n'
          '• كيف أغيّر اللغة؟ الإعدادات ← المظهر ← اللغة (أوّل خيار).\n'
          '• هل يعمل دون إنترنت؟ نعم، كل الميزات الأساسية تعمل دون اتصال.',
      'en': '• Is my data safe? Yes — local and encrypted, uploaded only if you enable sync yourself.\n'
          '• Forgot the backup password? It cannot be recovered — keep it somewhere safe.\n'
          '• Switched phones? Take an external backup from the old one and import it on the new one (or enable sync).\n'
          '• How do I change the language? Settings → Appearance → Language (first option).\n'
          '• Does it work offline? Yes, all core features work without a connection.',
      'tr': '• Verilerim güvende mi? Evet — yerel ve şifreli, yalnızca siz eşitlemeyi açarsanız yüklenir.\n'
          '• Yedek parolasını unuttum? Kurtarılamaz — güvenli bir yerde saklayın.\n'
          '• Telefon mu değiştirdiniz? Eskisinden harici yedek alıp yenisine aktarın (veya eşitlemeyi açın).\n'
          '• Dili nasıl değiştiririm? Ayarlar → Görünüm → Dil (ilk seçenek).\n'
          '• Çevrimdışı çalışır mı? Evet, tüm temel özellikler bağlantısız çalışır.',
      'es': '• ¿Mis datos están seguros? Sí — locales y cifrados, solo se suben si activas la sincronización.\n'
          '• ¿Olvidaste la contraseña de la copia? No se puede recuperar — guárdala en un lugar seguro.\n'
          '• ¿Cambiaste de teléfono? Haz una copia externa del antiguo e impórtala en el nuevo (o activa la sincronización).\n'
          '• ¿Cómo cambio el idioma? Ajustes → Apariencia → Idioma (primera opción).\n'
          '• ¿Funciona sin conexión? Sí, todas las funciones básicas funcionan sin conexión.',
      'fa': '• آیا داده‌هایم امن است؟ بله — محلی و رمزگذاری‌شده، فقط اگر خودتان همگام‌سازی را فعال کنید بارگذاری می‌شود.\n'
          '• گذرواژهٔ پشتیبان را فراموش کردم؟ قابل بازیابی نیست — جای امن نگه دارید.\n'
          '• گوشی عوض کردید؟ از قبلی پشتیبان بیرونی بگیرید و در جدید وارد کنید (یا همگام‌سازی را فعال کنید).\n'
          '• چگونه زبان را عوض کنم؟ تنظیمات ← ظاهر ← زبان (اولین گزینه).\n'
          '• آفلاین کار می‌کند؟ بله، همهٔ امکانات اصلی بدون اینترنت کار می‌کنند.',
      'id': '• Apakah data saya aman? Ya — lokal dan terenkripsi, diunggah hanya jika Anda mengaktifkan sinkronisasi.\n'
          '• Lupa kata sandi cadangan? Tidak bisa dipulihkan — simpan di tempat aman.\n'
          '• Ganti ponsel? Buat cadangan eksternal dari yang lama dan impor di yang baru (atau aktifkan sinkronisasi).\n'
          '• Cara mengubah bahasa? Pengaturan → Tampilan → Bahasa (opsi pertama).\n'
          '• Apakah bekerja offline? Ya, semua fitur inti bekerja tanpa koneksi.',
      'fr': "• Mes données sont-elles en sécurité ? Oui — locales et chiffrées, envoyées seulement si vous activez la synchro.\n"
          "• Mot de passe de sauvegarde oublié ? Il est irrécupérable — conservez-le en lieu sûr.\n"
          "• Changé de téléphone ? Faites une sauvegarde externe de l'ancien et importez-la sur le nouveau (ou activez la synchro).\n"
          "• Comment changer la langue ? Réglages → Apparence → Langue (première option).\n"
          "• Fonctionne-t-elle hors ligne ? Oui, toutes les fonctions principales marchent sans connexion.",
      'de': '• Sind meine Daten sicher? Ja — lokal und verschlüsselt, nur hochgeladen, wenn Sie die Synchronisierung selbst aktivieren.\n'
          '• Backup-Passwort vergessen? Es kann nicht wiederhergestellt werden — sicher aufbewahren.\n'
          '• Telefon gewechselt? Externe Sicherung vom alten erstellen und auf dem neuen importieren (oder Sync aktivieren).\n'
          '• Wie ändere ich die Sprache? Einstellungen → Aussehen → Sprache (erste Option).\n'
          '• Funktioniert es offline? Ja, alle Kernfunktionen arbeiten ohne Verbindung.',
    },
  ),
];
