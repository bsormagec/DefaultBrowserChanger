# DefaultBrowserChanger 🌐

macOS menü çubuğundan (tray) tek tıkla varsayılan web tarayıcısını değiştirmeyi sağlayan ultra hafif, yerel (native) bir menü çubuğu aracı.

---

## ✨ Özellikler

- **🌍 Şık Menü Çubuğu İkonu:** macOS menü çubuğunda sabit, modern ve temaya (Light / Dark mode) otomatik uyum sağlayan Globe ikonu.
- **🚀 Tek Tıkla Geçiş:** Yüklü tarayıcılar (Google Chrome, Safari, Arc, Brave, Firefox, Microsoft Edge, Comet, BrowserOS vb.) gerçek logolarıyla listelenir; tıkladığınız an varsayılan tarayıcı değişir.
- **⚡ Anında & Otomatik Onay:** macOS Sonoma ve Sequoia'nın güvenlik penceresi arka planda otomatik onaylanarak 0.1 saniye içinde pürüzsüz geçiş sağlanır.
- **🔔 Bildirim & Sesli Geri Bildirim:** Tarayıcı değiştiğinde macOS bildirimi ve zarif bir sesle durum bildirilir.
- **🔄 Launch at Login (Açılışta Otomatik Başlatma):** Menüden açılıp kapatılabilen, macOS `SMAppService` tabanlı yerel otomatik başlatma desteği.
- **⚙️ Sistem Ayarları Kısayolu:** Tek tıkla macOS Masaüstü ve Dock ayarlarına gitme imkanı.
- **🪶 Sıfır Yük (Pure Native Swift):** Harici framework gerektirmez, 2 MB'tan küçük boyut, sıfır CPU ve RAM kullanımı.

---

## 🛠️ Kurulum & Derleme

Uygulamayı derlemek ve doğrudan `/Applications` klasörünüze yüklemek için terminalde şu komutu çalıştırmanız yeterlidir:

```bash
# Derle ve /Applications klasörüne yükle
./build.sh --install
```

Ardından uygulamayı başlatmak için:

```bash
open /Applications/DefaultBrowserChanger.app
```

---

## 📋 Kullanım

1. Menü çubuğundaki **Globe (Dünya)** ikonuna tıklayın.
2. Açılan menüde o anki varsayılan tarayıcınızın yanında onay işareti (`✓`) göreceksiniz.
3. Geçmek istediğiniz tarayıcıya tıklayın:
   - Varsayılan tarayıcı anında değişir.
   - Onay işareti yeni tarayıcıya geçer.
   - Bildirim görünür.
4. **Launch at Login** seçeneğini işaretleyerek Mac'inizi her açtığınızda aracın hazır olmasını sağlayabilirsiniz.

---

## 🔒 Güvenlik & İzinler

macOS Sequoia / Sonoma, varsayılan tarayıcı değişimini korumalı bir işlem olarak ele alır. `DefaultBrowserChanger`, değişikliği otomatik olarak tamamlayabilmek için AppleScript / Accessibility API'sini kullanır. İlk kullanımda macOS bir kez onay isteyebilir; onay verdikten sonra tüm geçişler tamamen sessiz ve anında gerçekleşir.
