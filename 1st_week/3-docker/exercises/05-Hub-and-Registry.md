# Uygulama 5: Paylaşım ve Dağıtım (Registry)

Yaptığımız imajları başkalarıyla paylaşmak veya sunuculara dağıtmak için Docker Hub (veya kendi özel kayıtcımız) kullanılır.

## 1. Hazırlık
Önce paylaşmak istediğimiz imajı oluşturalım (Eğer yoksa).

```bash
docker pull alpine
```

## 2. Etiketleme (Tagging)
Bir imajı bir depoya gönderebilmek için isminin `KULLANICI_ADI/IMAJ_ADI:TAG` formatında olması gerekir.

```bash
# alpine imajına yeni bir etiket yapıştırıyoruz
# KULLANICI_ADINIZ yerine Docker Hub kullanıcı adınızı yazın
docker tag alpine abdussamed/my-alpine:v1
```

## 3. Giriş Yapma (Login)
Terminalden Docker Hub hesabımıza oturum açalım.

```bash
docker login
# Kullanıcı adı ve şifre soracak
```

## 4. Gönderme (Push)
İmajı buluta yükleyelim.

```bash
docker push abdussamed/my-alpine:v1
```

## 5. Simülasyon
Artık bu imaj Docker Hub'da. Lokaldeki imajı silip, Hub'dan tekrar çekebildiğimizi doğrulayalım.

```bash
# Yerel kopyayı sil
docker rmi abdussamed/my-alpine:v1

# Hub'dan çek
docker pull abdussamed/my-alpine:v1
```

Bu yöntemle, geliştirdiğiniz adli bilişim araçlarını tüm birimdeki bilgisayarlara tek komutla dağıtabilirsiniz.
