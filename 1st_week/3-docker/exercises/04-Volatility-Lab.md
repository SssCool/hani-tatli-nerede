# Uygulama 4: Adli Bilişim Laboratuvarı (Volatility Dockerization)

Bu, gerçek hayattan bir senaryodur. Eski bir Python sürümü gerektiren **Volatility 2.6** aracını, bilgisayarımıza hiçbir şey kurmadan (kirletmeden) Docker ile çalıştıracağız.

## Amaç
*   Karmaşık bağımlılıkları olan eski araçları konteynerleştirmek.
*   Geçici (Disposable) analiz konteynerleri kullanmak.
*   Host (Bilgisayar) dosyalarını konteyner içine bağlamak (Volume Mount).

## Adım 1: Dockerfile Hazırlama
`volatility-lab` adında bir klasör açın ve içine `Dockerfile` oluşturun:

```dockerfile
# Volatility 2.6 için Python 2.7 şart!
FROM python:2.7-slim

# Linux kütüphanelerini yükle (Yara, Distorm vb.)
RUN apt-get update && apt-get install -y \
    git build-essential libdistorm3-dev yara libraw1394-11 libcap2-bin

# Volatility kaynak kodunu GitHub'dan çek
WORKDIR /app
RUN git clone https://github.com/volatilityfoundation/volatility.git

# Python kütüphanelerini yükle
RUN pip install pycrypto distorm3 yara-python pillow openpyxl ujson

# Çalışma dizinini ayarla
WORKDIR /app/volatility

# Konteyner bir komut gibi çalışsın
ENTRYPOINT ["python", "vol.py"]
```

## Adım 2: İmajı Oluşturma
Aracımızı inşa edelim (Bu işlem internet hızına göre biraz sürebilir):

```bash
docker build -t adli-volatility .
```

## Adım 3: Analiz Yapma (Simülasyon)
Elinizde `supheli_dump.mem` adında bir RAM imajı olduğunu varsayalım (Yoksa bile komutun çalıştığını `help` ile göreceğiz).

Test için yardım menüsünü çağıralım:
```bash
docker run --rm adli-volatility -h
```

**Gerçek Analiz Senaryosu:**
Eğer `supheli.mem` dosyanız mevcut klasörde olsaydı, şu komutla analiz yapacaktınız:

```bash
docker run --rm -v $(pwd):/veri adli-volatility -f /veri/supheli.mem imageinfo
```

*   `--rm`: İş bitince konteyneri sil. (Çöp bırakma).
*   `-v $(pwd):/veri`: Bulunduğum klasörü, konteynerin içindeki `/veri` klasörüne aynala.
*   `imageinfo`: Volatility'nin imaj hakkında bilgi veren komutu.
