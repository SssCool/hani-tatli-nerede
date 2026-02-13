# Uygulama 3: Ağ ve Veri Yönetimi (Networking & Volumes)

Konteynerler doğası gereği geçicidir (Stateless). Verileri kalıcı yapmak (`Volume`) ve birbirleriyle güvenli konuşturmak (`Network`) için bu labı uygulayacağız.

## Bölüm 1: Veri Kaybını Simüle Etmek (Volume Yoksa ne Olur?)

1.  Bir Ubuntu çalıştırıp içine dosya yazalım.
    ```bash
    docker run -it --name gecici-ubuntu ubuntu bash
    echo "Çok gizli istihbarat verisi" > /veri.txt
    cat /veri.txt
    exit
    ```

2.  Konteyneri silelim.
    ```bash
    docker rm gecici-ubuntu
    ```

3.  Tekrar başlatalım. Veri duruyor mu?
    ```bash
    docker run -it --name yeni-ubuntu ubuntu cat /veri.txt
    # HATA: No such file or directory. Veri gitti!
    ```

---

## Bölüm 2: Kalıcı Veri (Named Volumes)

Docker'ın yönettiği güvenli bir alan (Volume) oluşturalım.

```bash
docker volume create istihbarat-db
```

Konteyneri bu volume ile başlatalım:
```bash
# -v volume_adi : konteyner_ici_yol
docker run -it --rm -v istihbarat-db:/arsiv ubuntu bash

# İçeride veriyi yaz
echo "Bu veri asla silinmez" > /arsiv/rapor.txt
exit
```

Konteyner silindi (`--rm` ile). Şimdi yeni bir tane açıp volume'u bağlayalım:
```bash
docker run -it --rm -v istihbarat-db:/arsiv ubuntu cat /arsiv/rapor.txt
# Çıktı: Bu veri asla silinmez
```

---

## Bölüm 3: Bind Mount (Host ile Paylaşım)

Kendi bilgisayarınızdaki bir klasörü konteynerin içine "aynalamak" için kullanılır. Geliştirme yaparken veya logları dışarı almak için idealdir.

```bash
mkdir -p ~/paylasilan-klasor
echo "Bilgisayarımdan Merhaba" > ~/paylasilan-klasor/not.txt

# Host klasörünü bağla
docker run -it --rm -v ~/paylasilan-klasor:/konteyner-klasoru ubuntu bash

# İçeride kontrol et
cat /konteyner-klasoru/not.txt
```

---

## Bölüm 4: Networking (İsimle Haberleşme)

Varsayılan ağda (Default Bridge) konteynerler birbirini İSİMLE tanımaz, IP gerekir.
Özel ağ oluşturursak, DNS servisi devreye girer.

1.  Özel ağ oluştur:
    ```bash
    docker network create operasyon-agi
    ```

2.  Sunucuyu başlat (ağa bağla):
    ```bash
    docker run -d --name veritabani --network operasyon-agi postgres
    ```

3.  İstemciyi başlat ve isimi ping'le:
    ```bash
    docker run -it --rm --network operasyon-agi alpine ping veritabani
    # Başarılı! IP bilmemize gerek kalmadı.
    ```
