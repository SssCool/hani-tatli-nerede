# DevOps İlkeleri: C.A.L.M.S Modeli

DevOps bir araç veya unvan değildir, bir felsefedir. Bu felsefeyi anlamak için dünya genelinde kabul görmüş **C.A.L.M.S** modelini kullanırız.

## 1. Culture (Kültür)
En önemli maddedir. Araçlar değişir ama kültür baki kalır.
*   **İletişim:** Ekipler arası duvarları yıkmak.
*   **Suçlamama:** Bir hata olduğunda "Kim yaptı?" yerine "Neden oldu ve sistem bunu nasıl engelleyemedi?" diye sormak.
*   **Paylaşım:** Bilgiyi kendine saklama (Silo), herkese aç.

## 2. Automation (Otomasyon)
"Tekrar eden her şeyi otomatize et."
*   Manuel yapılan işler hataya açıktır ve yavaştır.
*   Testleri, kod derlemeyi, sunucu kurulumunu, ağ ayarlarını scriptler ve araçlarla (Ansible, Jenkins, Terraform) yap.

## 3. Lean (Yalın Düşünce)
Süreçteki "İsrafı" (Waste) yok et.
*   Gereksiz beklemeler, onay mekanizmaları, kullanılmayan kodlar israftır.
*   Küçük paketler halinde (Batch Size) çalışarak hataları hızlı fark et.

## 4. Measurement (Ölçümleme)
"Ölçemediğin şeyi yönetemezsin."
*   **MTTR (Mean Time To Recovery):** Sistem çöktüğünde ne kadar sürede ayağa kalkıyor?
*   **Deployment Frequency:** Ne sıklıkla güncelleme çıkıyoruz?
*   **Change Failure Rate:** Yaptığımız değişikliklerin yüzde kaçı hataya sebep oluyor?

## 5. Sharing (Paylaşım)
Deneyimleri, başarıları ve başarısızlıkları paylaşmak.
*   **Post-Mortem:** Bir kriz sonrası, olayın kök neden analizi yapılıp tüm şirketle paylaşılır ki aynı hata tekrar yapılmasın.
