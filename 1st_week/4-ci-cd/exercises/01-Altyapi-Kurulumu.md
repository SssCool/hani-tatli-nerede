# Uygulama 1: DevOps Altyapı Kurulumu

Bu bölümde, katılımcıların kullandığı gerçek **Jenkins** ve **GitLab** ortamını Docker Compose ile ayağa kaldıracağız. Bu altyapı, tüm CI/CD operasyonumuzun kalbi olacak.

## Dizini Hazırlama
Masaüstünde veya çalışma alanınızda `devops-lab` adında bir klasör oluşturun ve içine girin. Verilerin kaybolmaması için `volumes` klasörlerini host makinede tutacağız.

```bash
mkdir -p ~/devops-lab/gitlab-data
mkdir -p ~/devops-lab/jenkins-data
cd ~/devops-lab
```

---

## 1. GitLab Sunucusu

GitLab, kodlarımızı barındıracağımız "Repo Evi"mizdir.
Verilen konfigürasyona göre `docker-compose-gitlab.yml` dosyasını oluşturun:

```yaml
version: '3.8'
services:
  gitlab:
    image: yrzr/gitlab-ce-arm64v8:latest  # M1/M2 Mac'ler için ARM uyumlu imaj
    container_name: gitlab
    privileged: true
    restart: always
    hostname: 'gitlab.local'
    environment:
      GITLAB_OMNIBUS_CONFIG: |
        # Bu IP adresi sizin makinenizin veya VM'inizin IP si olmalı
        # Docker Network içinden erişim için 'gitlab' hostname'i de kullanılabilir
        external_url 'http://192.168.64.2'
    ports:
      - '80:80'
      - '443:443'
      - '2222:22'
    volumes:
      - './gitlab-data/config:/etc/gitlab'
      - './gitlab-data/logs:/var/log/gitlab'
      - './gitlab-data/data:/var/opt/gitlab'
    shm_size: '256m'
```

**Çalıştırma:**
```bash
docker-compose -f docker-compose-gitlab.yml up -d
```
*Not: GitLab'ın açılması 5-10 dakika sürebilir. `docker logs -f gitlab` ile takip edebilirsiniz.*

---

## 2. Jenkins Sunucusu

Jenkins, otomasyon motorumuzdur. İçinde Docker çalıştırabilmesi (Dind - Docker in Docker) için socket paylaşımı yapıyoruz.

`docker-compose-jenkins.yml` dosyasını oluşturun:

```yaml
version: '3.8'
services:
  jenkins:
    image: jenkins/jenkins:lts
    container_name: jenkins
    privileged: true
    restart: always
    user: root   # Docker socket'e erişim için root (Eğitim amaçlı)
    ports:
      - '8080:8080'
      - '50000:50000'
    volumes:
      - './jenkins-data:/var/jenkins_home'
      # Host makinenin Docker motorunu Jenkins'e kullandırıyoruz
      - '/var/run/docker.sock:/var/run/docker.sock'
      # Docker CLI'ı içeri aktarıyoruz
      - '/usr/bin/docker:/usr/bin/docker'
    environment:
      - TZ=Europe/Istanbul
```

**Çalıştırma:**
```bash
docker-compose -f docker-compose-jenkins.yml up -d
```

---

## 3. Erişim Testleri

1.  **GitLab:** Tarayıcıdan `http://192.168.64.2` (veya sizin IP'niz) adresine gidin. İlk açılışta `root` şifresini almanız gerekebilir:
    ```bash
    docker exec -it gitlab grep 'Password:' /etc/gitlab/initial_root_password
    ```

2.  **Jenkins:** Tarayıcıdan `http://localhost:8080` adresine gidin. Başlangıç şifresi için:
    ```bash
    docker exec jenkins cat /var/jenkins_home/secrets/initialAdminPassword
    ```

Ortamımız hazır! Şimdi bu iki devin birbirine "merhaba" demesini sağlayacağız.
