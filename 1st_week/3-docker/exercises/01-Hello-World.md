# Uygulama 1: Docker Merhaba Kiti (Hello World)

Bu egzersizde Docker'ın en temel komutlarını kullanarak hazır bir web sunucusunu (Nginx) ayağa kaldıracağız.

## Amaç
*   Docker Hub'dan imaj indirmek (`pull`).
*   Konteyner başlatmak (`run`).
*   Port yönlendirmesi mantığını anlamak (`-p`).
*   Konteynerin yaşam döngüsünü yönetmek (`stop`, `rm`).

## Adım 1: İmajı İndirme
Önce yerel bilgisayarımıza Nginx imajını çekelim.

```bash
docker pull nginx:latest
```

## Adım 2: Konteyneri Başlatma
İndirdiğimiz imajdan bir "çalışan örnek" (konteyner) oluşturalım.
*   `-d`: Detached mode (Arka planda çalış).
*   `-p 8080:80`: Bilgisayarımın 8080 portunu, konteynerin 80 portuna bağla.
*   `--name web-sunucum`: Konteynere isim ver.

```bash
docker run -d -p 8080:80 --name web-sunucum nginx:latest
```

## Adım 3: Test Etme
Tarayıcınızı açın ve `http://localhost:8080` adresine gidin. "Welcome to nginx!" yazısını görüyorsanız başardınız!

## Adım 4: İnceleme ve Temizlik
Çalışan konteyneri görelim:
```bash
docker ps
```

İşimizi bitirelim ve silelim:
```bash
docker stop web-sunucum
docker rm web-sunucum
```
