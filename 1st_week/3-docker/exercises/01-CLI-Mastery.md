# Uygulama 1: Docker CLI Ustalık Sınıfı

Bu laboratuvar çalışmasında, Docker arayüzüne (CLI) hakimiyetinizi en üst seviyeye çıkaracağız. Konteyner yaşam döngüsünü, log yönetimini ve temizlik işlemlerini derinlemesine inceleyeceğiz.

## Bölüm 1: Hello World ve Mimarisi
Docker'ın çalıştığını doğrulamakla başlayalım.

```bash
docker run hello-world
```

**Arka Planda Neler Oldu?**
1.  **Docker Client:** `run` komutunu Daemon'a iletti.
2.  **Docker Daemon:** `hello-world` imajını yerel depoda (Local Cache) aradı.
3.  **Registry:** Bulamayınca Docker Hub'a gitti, imajı indirdi (Pull).
4.  **Container:** İmajdan bir konteyner oluşturdu, çalıştırdı.
5.  **Output:** Konteyner ekrana yazıyı bastı ve görevi bittiği için kapandı (Exited).

---

## Bölüm 2: Konteyner Yönetimi (Life Cycle)

Bir Ubuntu konteyneri başlatalım ve içine girelim.
*   `-i` (Interactive): STDIN'i açık tut (Klavye girdisi yollayabilelim).
*   `-t` (TTY): Bize sahte bir terminal (Pseudo-TTY) ver.

```bash
docker run -it ubuntu bash
```

İçeride şunları deneyin:
```bash
ls /           # Dosya sistemini gör
whoami         # root olduğunu gör
cat /etc/issue # Ubuntu sürümüne bak
exit           # Çıkış yap (Konteyner durur!)
```

**Soru:** `exit` deyince konteyner neden kapandı?
**Cevap:** Konteynerler, içindeki ana süreç (PID 1 - burada `bash`) çalıştığı sürece yaşar. `bash` kapanınca konteyner de ölür.

---

## Bölüm 3: Arka Planda Çalıştırma (Detached Mode)

Web sunucuları gibi sürekli çalışması gereken servisler için `-d` kullanılır.

```bash
# Nginx'i başlat, ismini 'web-server' koy
docker run -d --name web-server nginx

# Çalışıyor mu?
docker ps

# Loglarını gör (Canlı takip için -f)
docker logs -f web-server
```

**Konteyner'a Dışarıdan Komut Yollama (`exec`)**
Çalışan bir konteynerin içine girmeden veya yanına yeni bir süreç ekleyerek işlem yapabiliriz.

```bash
# Konteyner içinde 'ls' komutunu çalıştır
docker exec web-server ls /etc/nginx

# Çalışan konteynerin içine interaktif terminal ile gir
docker exec -it web-server bash
# (İçeride configuration dosyalarını inceleyebilirsiniz)
exit
```

---

## Bölüm 4: Temizlik ve Bakım (Prune)

Zamanla sistemde yüzlerce durmuş konteyner ve kullanılmayan imaj birikir.

```bash
# Durmuş (Exited) tüm konteynerleri sil
docker container prune

# Kullanılmayan (Dangling - tagsız) imajları sil
docker image prune

# Her şeyi temizle (DİKKAT! Volume ve Networkler dahil)
# docker system prune -a --volumes
```
