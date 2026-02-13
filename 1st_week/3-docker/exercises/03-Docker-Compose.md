# Uygulama 3: Servisleri Orkestre Etmek (Docker Compose)

Tek bir konteyner yetmez. Şimdi bir Web Sunucusu ve bir Veritabanını (Redis) aynı anda, tek komutla ayağa kaldıracağız.

## Amaç
*   `docker-compose.yml` yazmak.
*   Servisler arası ağ bağlantısını anlamak.
*   Tüm mimariyi tek komutla yönetmek.

## Adım 1: Compose Dosyasını Yazma
Boş bir klasörde `docker-compose.yml` adında bir dosya oluşturun:

```yaml
version: '3.8'

services:
  # 1. Servis: Web Arayüzü (Hazır bir sayaç uygulaması)
  web:
    image: dockersamples/visualizer:stable
    ports:
      - "8080:8080"
    volumes:
      - "/var/run/docker.sock:/var/run/docker.sock"
    networks:
      - benim-agim

  # 2. Servis: Önbellek (Redis)
  redis:
    image: redis:alpine
    networks:
      - benim-agim

# Özel bir ağ tanımlıyoruz
networks:
  benim-agim:
```

## Adım 2: Sistemi Başlatma (Up)
```bash
docker-compose up -d
```
`-d`: Detached (Arka planda) çalıştır. Docker gerekli imajları indirecek ve iki konteyneri de başlatacaktır.

## Adım 3: Kontrol
Tarayıcıdan `http://localhost:8080` adresine gidin. Docker Visualizer uygulamasını göreceksiniz. Bu uygulama, arka planda çalışan konteynerleri görselleştirir.

## Adım 4: Sistemi Kapatma (Down)
Her şeyi temizlemek için:
```bash
docker-compose down
```
Bu komut konteynerleri durdurur, siler ve oluşturduğu sanal ağı da yok eder.
