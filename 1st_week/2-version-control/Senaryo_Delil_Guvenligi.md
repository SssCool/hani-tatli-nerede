# Git ve Delil Güvenliği (Chain of Custody)

Kendi geliştirdiğiniz bir analiz yazılımını veya scripti bir davada kullandığınızda, savunma makamı "Bu yazılım hatalı, delilleri yanlış yorumluyor" veya "Delilleri manipüle ediyor" diyebilir.

DevOps pratikleri burada hukuki bir kalkan sağlar.

## 1. Versiyonlama ile Şeffaflık
Yazılımınızın kaynak kodları Git üzerinde tarihçeli olarak tutuluyorsa:
*   Olay tarihinde (örn: 12 Şubat 2024), analiz yazılımının **v2.1.4** sürümünün kullanıldığı,
*   Bu sürümde hangi algoritmaların çalıştığı,
*   Kodun son değişikliğinin kim tarafından yapıldığı (Ahmet Komiser mi, Mehmet Başkomiser mi?)

Git logları ile saniyesine kadar ispatlanabilir.

## 2. Code Review ile Güvenilirlik
Analiz aracının tek bir kişinin inisiyatifinde (Ahmet Komiser'in USB belleğinde) olmadığını, kurumsal bir **Code Review** sürecinden geçtiğini, yani en az 2-3 uzmanın onayıyla canlıya alındığını göstermek, yazılımın güvenilirliğini artırır.

## 3. Konfigürasyon Yönetimi (Config as Code)
Sahadaki 100 farklı analiz sunucusunun ayarlarının (Hangi loglar toplanıyor? Firewall kuralları ne?) bir Git reposunda tutulmasıdır.
*   Birisi sunucuya girip ayarı elle değiştirirse, Git bunu tespit eder.
*   İzinsiz değişiklikleri önler ve denetlenebilirlik (Audit) sağlar.
