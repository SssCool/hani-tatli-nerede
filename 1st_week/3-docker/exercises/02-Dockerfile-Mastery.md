# Uygulama 2: Dockerfile Ustalık Sınıfı

Bu bölümde, sıfırdan "Production-Ready" (Canlı ortama uygun) imajlar hazırlamayı öğreneceğiz.

## Bölüm 1: İlk Dockerfile (Python Web Server)

Proje klasörünü hazırlayalım:
```bash
mkdir -p ~/docker-labs/ex2 && cd ~/docker-labs/ex2
```

`app.py` dosyasını oluşturalım:
```python
import os
from http.server import HTTPServer, SimpleHTTPRequestHandler

print("Uygulama Başlıyor...")
HTTPServer(('0.0.0.0', 8080), SimpleHTTPRequestHandler).serve_forever()
```

`Dockerfile` yazalım:
```dockerfile
# 1. Taban İmaj (Base Image)
FROM python:3.12-slim

# 2. Metadata (Etiketleme)
LABEL maintainer="Siber Operasyon Ekibi"
LABEL version="1.0"

# 3. Çalışma Dizini
WORKDIR /app

# 4. Dosyaları Kopyala
COPY app.py .

# 5. Port Bildirimi (Dokümantasyon amaçlı)
EXPOSE 8080

# 6. Başlatma Komutu
CMD ["python", "app.py"]
```

Build ve Run:
```bash
docker build -t my-python-app:v1 .
docker run -d -p 8080:8080 my-python-app:v1
```

---

## Bölüm 2: İleri Seviye Direktifler (Env, Healthcheck, User)

Gerçek hayatta uygulamalar parametrik olmalı, kendini root yetkisinden arındırmalı ve sağlığını raporlamalıdır.

Gelişmiş `Dockerfile`:
```dockerfile
FROM python:3.12-slim

# Güvenlik: Root olmayan kullanıcı oluştur
RUN groupadd -r appgroup && useradd -r -g appgroup appuser

# Ortam Değişkeni (Varsayılan değer)
ENV APP_PORT=8080

WORKDIR /app
COPY app.py .

# Dosya sahipliğini kullanıcıya ver
RUN chown appuser:appgroup app.py

# Kullanıcıya geç (Buradan sonraki komutlar appuser ile çalışır)
USER appuser

# Sağlık Kontrolü
HEALTHCHECK --interval=30s --timeout=3s \
  CMD curl -f http://localhost:8080/ || exit 1

CMD ["python", "app.py"]
```

---

## Bölüm 3: Multi-Stage Build (Boyut Optimizasyonu)

Go ile yazılmış bir uygulamanız olduğunu düşünün. Derlemek için 800MB'lık `golang` imajına ihtiyacınız var. Ama uygulama çalışırken sadece 10MB'lık binary dosyası yeterli.

`main.go`:
```go
package main
import "fmt"
func main() { fmt.Println("Merhaba Siber Güvenlik!") }
```

Multi-Stage `Dockerfile`:
```dockerfile
# --- Aşama 1: İnşaat (Builder) ---
FROM golang:1.21 AS builder
WORKDIR /src
COPY main.go .
RUN go build -o operasyon-araci main.go

# --- Aşama 2: Operasyon (Runner) ---
# Alpine: Çok küçük (5MB) Linux dağıtımı
FROM alpine:latest
WORKDIR /root/
# Sadece derlenmiş dosyayı kopyala (Builder aşamasından al)
COPY --from=builder /src/operasyon-araci .

CMD ["./operasyon-araci"]
```

**Sonuç:** `docker build` yaptığınızda yüzlerce MB yerine sadece ~15 MB'lık bir imaj elde edersiniz.
