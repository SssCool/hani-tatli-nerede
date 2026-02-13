# Uygulama 4: Orkestrasyon Laboratuvarı (Docker Compose)

Tek komutla tam kapsamlı bir web mimarisi (Uygulama + Veritabanı) kuracağız.

## Senaryo: Flask Web App + PostgreSQL
Python uygulamamız, PostgreSQL veritabanına bağlanacak ve versiyon bilgisini ekrana basacak.

Klasör yapısını kurun:
```bash
mkdir -p ~/docker-labs/ex4 && cd ~/docker-labs/ex4
```

### 1. Dosyaları Oluşturun

**`app.py`**:
```python
from flask import Flask
import psycopg2
import os

app = Flask(__name__)

@app.route('/')
def hello():
    try:
        conn = psycopg2.connect(
            host=os.environ['DB_HOST'],
            user=os.environ['DB_USER'],
            password=os.environ['DB_PASS'],
            dbname=os.environ['DB_NAME']
        )
        cur = conn.cursor()
        cur.execute('SELECT version()')
        db_ver = cur.fetchone()
        conn.close()
        return f"<h1>Bağlantı Başarılı!</h1><p>DB Versiyon: {db_ver}</p>"
    except Exception as e:
        return f"<h1>Hata!</h1><p>{str(e)}</p>"

if __name__ == "__main__":
    app.run(host='0.0.0.0', port=5000)
```

**`requirements.txt`**:
```text
flask
psycopg2-binary
```

**`Dockerfile`**:
```dockerfile
FROM python:3.12-slim
WORKDIR /app
COPY requirements.txt .
RUN pip install -r requirements.txt
COPY app.py .
CMD ["python", "app.py"]
```

**`docker-compose.yml`**:
```yaml
version: '3.8'

services:
  # Web Uygulamamız
  web:
    build: .
    ports:
      - "5000:5000"
    environment:
      - DB_HOST=db       # Servis ismini kullanıyoruz (DNS)
      - DB_NAME=appdb
      - DB_USER=user
      - DB_PASS=secret
    depends_on:
      - db               # DB başlamadan web başlama

  # Veritabanı Servisi
  db:
    image: postgres:15-alpine
    environment:
      POSTGRES_DB=appdb
      POSTGRES_USER=user
      POSTGRES_PASSWORD=secret
    volumes:
      -pg-data:/var/lib/postgresql/data  # Kalıcı veri

# Volume Tanımı
volumes:
  pg-data:
```

### 2. Büyük Açılış (Up)

```bash
docker-compose up -d
```

*   İmajlar oluşturulur/indirilir.
*   Ağlar kurulur.
*   Konteynerler başlatılır.

### 3. Test ve Yönetim

*   Tarayıcıda `http://localhost:5000` adresine gidin. Veritabanı sürümünü görmelisiniz.
*   Logları izleyin: `docker-compose logs -f`
*   Bir servisi yeniden başlatın: `docker-compose restart web`
*   Her şeyi kapatın (Veriler korunur): `docker-compose down`
*   Her şeyi silin (Veriler dahil): `docker-compose down -v`
