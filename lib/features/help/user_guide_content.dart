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

/// مواضيع الدليل بالترتيب. الشرح مفصّل في العربية/الإنجليزية/التركية/الإسبانية،
/// ويرجع للإنجليزية في بقية اللغات.
const List<GuideTopic> guideTopics = [
  GuideTopic(
    'start',
    Icons.rocket_launch_outlined,
    {
      'ar': 'البدء السريع',
      'en': 'Getting started',
      'tr': 'Hızlı başlangıç',
      'es': 'Primeros pasos',
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
    },
    {
      'ar': 'حدّد النصّ ثم استخدم شريط الأدوات:\n\n'
          '• غامق/مائل/تحته خطّ/يتوسّطه خطّ، ألوان نصّ وتظليل.\n'
          '• عناوين، قوائم نقطية ومرقّمة، اقتباس، كتلة شيفرة، مهامّ.\n'
          '• محاذاة (يمين/وسط/يسار) وتباعد الأسطر.\n'
          '• اتجاه ذكيّ لكل سطر: يكتشف العربية/الإنجليزية تلقائيًّا.\n'
          '• تصدير الملاحظة PDF أو Word، أو مشاركتها كصورة.\n'
          '• يمكنك تخصيص الأزرار الظاهرة من: الإعدادات ← الملاحظات والمحرّر ← أزرار شريط التنسيق.',
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
    },
    {
      'ar': 'كل بياناتك محليّة ومشفّرة. للحماية الإضافية:\n\n'
          '• قفل التطبيق: الإعدادات ← الأمان والبيانات ← الأمان → فعّل القفل واضبط رقمًا سرّيًّا، '
          'وفعّل البصمة/الوجه إن رغبت. سيُطلب عند فتح التطبيق.\n'
          '• قفل ملاحظة بعينها: من خيارات الملاحظة (اضغط مطوّلًا) → قفل. تتطلّب فتحًا لعرضها.\n'
          '• القسم السرّي: ملاحظات مخفيّة لا تظهر إلا بعد فكّ القفل.\n'
          '• ملاحظات كلمات المرور والملاحظات المقفلة: يُمنع تصوير شاشتها تلقائيًّا.',
      'en': 'All your data is local and encrypted. For extra protection:\n\n'
          '• App lock: Settings → Security & data → Security → enable the lock and set a PIN, '
          'and enable biometrics if you like. It is requested when opening the app.\n'
          '• Lock a specific note: from the note options (long-press) → Lock. It requires unlocking to view.\n'
          '• Secret section: hidden notes that only appear after unlocking.\n'
          '• Password notes and locked notes: screenshots are blocked automatically.',
      'tr': 'Tüm verileriniz yereldir ve şifrelidir. Ek koruma için:\n\n'
          '• Uygulama kilidi: Ayarlar → Güvenlik ve veriler → Güvenlik → kilidi açın ve bir PIN belirleyin, '
          'isterseniz biyometriyi etkinleştirin. Uygulama açılırken istenir.\n'
          '• Belirli bir notu kilitleyin: not seçeneklerinden (uzun basın) → Kilitle. Görmek için kilit açma gerekir.\n'
          '• Gizli bölüm: yalnızca kilit açıldıktan sonra görünen gizli notlar.\n'
          '• Parola notları ve kilitli notlar: ekran görüntüsü otomatik engellenir.',
      'es': 'Todos tus datos son locales y cifrados. Para mayor protección:\n\n'
          '• Bloqueo de la app: Ajustes → Seguridad y datos → Seguridad → activa el bloqueo y define un PIN, '
          'y activa la biometría si quieres. Se pide al abrir la app.\n'
          '• Bloquear una nota: en las opciones de la nota (mantén pulsado) → Bloquear. Requiere desbloqueo para verla.\n'
          '• Sección secreta: notas ocultas que solo aparecen tras desbloquear.\n'
          '• Notas de contraseñas y notas bloqueadas: las capturas se bloquean automáticamente.',
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
    },
    {
      'ar': 'كل النسخ مشفّرة AES‑256 بكلمة مرور تحدّدها (دونها لا يمكن الاستعادة — احفظها!).\n\n'
          'افتح: الإعدادات ← الأمان والبيانات ← النسخ الاحتياطي.\n'
          '• نسخة تلقائية يومية: مفعّلة افتراضيًّا، تُحفظ داخل الجهاز (٧ خانات أسبوعيّة).\n'
          '• تصدير نسخة: تحفظ ملفًّا مشفّرًا في الجهاز.\n'
          '• مشاركة للسحابة: أرسل النسخة لأي تطبيق (Drive/تيليجرام…).\n'
          '• الاستعادة: «استعادة من نسخة» — مع لقطة أمان تتيح التراجع بضغطة.\n'
          '• التحقّق: تأكّد أن النسخة سليمة دون تطبيقها.\n\n'
          '💡 النسخة الداخلية تُحذف عند إلغاء التثبيت — خذ نسخة خارجية (تصدير/مشاركة) دوريًّا.',
      'en': 'All backups are AES‑256 encrypted with a password you set (without it they cannot be restored — keep it!).\n\n'
          'Open: Settings → Security & data → Backup.\n'
          '• Daily auto-backup: on by default, stored on the device (7 weekly slots).\n'
          '• Export backup: saves an encrypted file to the device.\n'
          '• Share to cloud: send the backup to any app (Drive/Telegram…).\n'
          '• Restore: “Restore from backup” — with a safety snapshot so you can undo with one tap.\n'
          '• Verify: confirm a backup is intact without applying it.\n\n'
          '💡 The internal backup is removed on uninstall — take an external backup (export/share) regularly.',
      'tr': 'Tüm yedekler, belirlediğiniz bir parolayla AES‑256 ile şifrelenir (parola olmadan geri yüklenemez — saklayın!).\n\n'
          'Açın: Ayarlar → Güvenlik ve veriler → Yedekleme.\n'
          '• Günlük otomatik yedek: varsayılan olarak açık, cihazda saklanır (7 haftalık slot).\n'
          '• Yedeği dışa aktar: cihaza şifreli bir dosya kaydeder.\n'
          '• Buluta paylaş: yedeği herhangi bir uygulamaya gönderin (Drive/Telegram…).\n'
          '• Geri yükle: “Yedekten geri yükle” — geri almayı sağlayan güvenlik anlık görüntüsüyle.\n'
          '• Doğrula: bir yedeğin sağlam olduğunu uygulamadan onaylayın.\n\n'
          '💡 İç yedek, kaldırmada silinir — düzenli olarak harici yedek (dışa aktar/paylaş) alın.',
      'es': 'Todas las copias se cifran con AES‑256 con una contraseña que tú defines (sin ella no se pueden restaurar — ¡guárdala!).\n\n'
          'Abre: Ajustes → Seguridad y datos → Copia de seguridad.\n'
          '• Copia automática diaria: activada por defecto, guardada en el dispositivo (7 ranuras semanales).\n'
          '• Exportar copia: guarda un archivo cifrado en el dispositivo.\n'
          '• Compartir a la nube: envía la copia a cualquier app (Drive/Telegram…).\n'
          '• Restaurar: “Restaurar desde copia” — con una instantánea de seguridad para deshacer con un toque.\n'
          '• Verificar: confirma que una copia está íntegra sin aplicarla.\n\n'
          '💡 La copia interna se borra al desinstalar — haz una copia externa (exportar/compartir) con regularidad.',
    },
  ),
  GuideTopic(
    'sync',
    Icons.cloud_sync_outlined,
    {
      'ar': 'المزامنة السحابية (تهيئة خطوة بخطوة)',
      'en': 'Cloud sync (step-by-step setup)',
      'tr': 'Bulut eşitleme (adım adım kurulum)',
      'es': 'Sincronización en la nube (configuración paso a paso)',
    },
    {
      'ar': 'مزامنة مشفّرة طرفيًّا (E2E): الخادم لا يقرأ ملاحظاتك. تُزامَن النصوص والقوائم '
          'والوسوم والتصنيفات (المرفقات تُحفظ عبر النسخة الكاملة).\n\n'
          'افتح: الإعدادات ← الأمان والبيانات ← النسخ الاحتياطي ← تبويب «المزامنة السحابية».\n\n'
          '— الطريقة الأسهل WebDAV (بلا إعداد خارجيّ):\n'
          '١) اختر «WebDAV».\n'
          '٢) أدخل رابط المجلّد على خادمك (مثال Nextcloud: '
          'https://cloud.example.com/remote.php/dav/files/USER/Notes) واسم المستخدم وكلمة المرور.\n'
          '٣) أدخل «عبارة التشفير» نفسها على كل أجهزتك.\n'
          '٤) اضغط «اختبار الاتصال» ثم «مزامنة الآن».\n\n'
          '— Google Drive: يتطلّب إعدادًا لمرّة واحدة في Google Cloud (مشروع + تفعيل Drive API '
          '+ عميل OAuth أندرويد باسم الحزمة وبصمة SHA‑1 + إضافة بريدك كـ Test user). راجع المطوّر '
          'إن ظهر خطأ تسجيل الدخول.\n\n'
          '💡 ضع «عبارة التشفير» ذاتها على كل الأجهزة، وإلا تعذّر فكّ التشفير. يدمج التطبيق '
          '«آخر تعديل يفوز» لكل ملاحظة فلا تضيع البيانات.',
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
          '+ an Android OAuth client with the package name and SHA‑1 + add your email as a Test user). '
          'Ask the developer if sign-in fails.\n\n'
          '💡 Use the same passphrase on every device, otherwise decryption fails. The app merges '
          '“last edit wins” per note so nothing is lost.',
      'tr': 'Uçtan uca şifreli (E2E) eşitleme: sunucu notlarınızı okuyamaz. Metin, listeler, '
          'etiketler ve kategoriler eşitlenir (ekler tam yedek ile saklanır).\n\n'
          'Açın: Ayarlar → Güvenlik ve veriler → Yedekleme → “Bulut eşitleme” sekmesi.\n\n'
          '— En kolayı: WebDAV (harici kurulum yok):\n'
          '1) “WebDAV” seçin.\n'
          '2) Sunucu klasör adresinizi (Nextcloud örneği: '
          'https://cloud.example.com/remote.php/dav/files/USER/Notes), kullanıcı adı ve parolayı girin.\n'
          '3) Tüm cihazlarınızda aynı “şifreleme parolasını” girin.\n'
          '4) “Bağlantıyı test et”e, sonra “Şimdi eşitle”ye dokunun.\n\n'
          '— Google Drive: Google Cloud’da tek seferlik kurulum gerektirir (bir proje + Drive API’yi etkinleştirme '
          '+ paket adı ve SHA‑1 ile bir Android OAuth istemcisi + e-postanızı Test kullanıcısı olarak ekleme). '
          'Oturum açma başarısız olursa geliştiriciye danışın.\n\n'
          '💡 Her cihazda aynı parolayı kullanın, yoksa şifre çözme başarısız olur. Uygulama not başına '
          '“son düzenleme kazanır” olarak birleştirir, böylece veri kaybolmaz.',
      'es': 'Sincronización cifrada de extremo a extremo (E2E): el servidor no puede leer tus notas. '
          'Se sincronizan texto, listas, etiquetas y categorías (los adjuntos se guardan en la copia completa).\n\n'
          'Abre: Ajustes → Seguridad y datos → Copia de seguridad → pestaña “Sincronización en la nube”.\n\n'
          '— Lo más fácil: WebDAV (sin configuración externa):\n'
          '1) Elige “WebDAV”.\n'
          '2) Introduce la URL de la carpeta de tu servidor (ejemplo Nextcloud: '
          'https://cloud.example.com/remote.php/dav/files/USER/Notes), usuario y contraseña.\n'
          '3) Introduce la misma “frase de cifrado” en todos tus dispositivos.\n'
          '4) Toca “Probar conexión” y luego “Sincronizar ahora”.\n\n'
          '— Google Drive: requiere una configuración única en Google Cloud (un proyecto + activar Drive API '
          '+ un cliente OAuth de Android con el nombre del paquete y el SHA‑1 + añadir tu correo como usuario de prueba). '
          'Consulta al desarrollador si falla el inicio de sesión.\n\n'
          '💡 Usa la misma frase en todos los dispositivos, o el descifrado fallará. La app fusiona '
          '“la última edición gana” por nota, así no se pierde nada.',
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
    },
    {
      'ar': '• ويدجت الشاشة الرئيسية: أضِف ويدجت «ملاحظات» لشاشة هاتفك لعرض ملاحظاتك.\n'
          '• تثبيت في الإشعارات: من خيارات الملاحظة — تبقى كإشعار صامت مستمرّ أمامك.\n'
          '• مشاركة كصورة / تصدير PDF / تصدير Word لأي ملاحظة.\n'
          '• الكتابة الصوتية (الإملاء): زرّ الميكروفون في المحرّر يحوّل صوتك إلى نصّ.\n'
          '• الملخّص الأسبوعي والتنظيف: من القائمة الجانبية.',
      'en': '• Home-screen widget: add the Notes widget to your phone’s home screen.\n'
          '• Pin to notifications: from the note options — stays as a silent ongoing notification.\n'
          '• Share as image / export PDF / export Word for any note.\n'
          '• Voice typing (dictation): the mic button in the editor turns speech into text.\n'
          '• Weekly summary and Clean-up: from the side menu.',
      'tr': '• Ana ekran widget’ı: telefonunuzun ana ekranına Notlar widget’ını ekleyin.\n'
          '• Bildirimlere sabitle: not seçeneklerinden — sessiz kalıcı bir bildirim olarak kalır.\n'
          '• Görsel olarak paylaş / PDF dışa aktar / Word dışa aktar.\n'
          '• Sesle yazma (dikte): düzenleyicideki mikrofon düğmesi konuşmayı metne çevirir.\n'
          '• Haftalık özet ve Temizlik: yan menüden.',
      'es': '• Widget de pantalla de inicio: añade el widget de Notas a tu pantalla.\n'
          '• Fijar en notificaciones: desde las opciones de la nota — queda como notificación silenciosa.\n'
          '• Compartir como imagen / exportar PDF / exportar Word.\n'
          '• Dictado por voz: el botón del micrófono en el editor convierte voz en texto.\n'
          '• Resumen semanal y Limpieza: desde el menú lateral.',
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
    },
  ),
];
