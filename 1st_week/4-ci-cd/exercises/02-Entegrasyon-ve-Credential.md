# Uygulama 2: Entegrasyon, Yetkiler ve Webhooklar

Jenkins ile GitLab'ın konuşabilmesi ve Jenkins'in Docker Hub'a imaj atabilmesi için gerekli "anahtarları" (Credentials) tanımlayacağız.

## 1. GitLab Hazırlığı (Access Token)

Jenkins'in GitLab'dan kod çekebilmesi ve "Build Durumunu" (Pending/Success) GitLab'a bildirebilmesi için bir Token'a ihtiyacı vardır.

1.  GitLab'da `root` kullanıcısı ile giriş yapın.
2.  Sağ üst profil -> **Edit Profile** -> **Access Tokens**.
3.  **Name:** `jenkins-token`
4.  **Scopes:** `api`, `read_repository`, `write_repository` seçin.
5.  **Create Personal Access Token** deyin ve çıkan şifreyi kopyalayın.

## 2. Docker Hub Hazırlığı (PAT)

Jenkins'in imajları Docker Hub'a `push` edebilmesi için şifre yerine **Personal Access Token (PAT)** kullanması güvenlik gereğidir.

1.  [hub.docker.com](https://hub.docker.com) adresine gidin.
2.  Profil -> **Account Settings** -> **Security** -> **New Access Token**.
3.  **Description:** `jenkins-ci`
4.  Access: **Read & Write**.
5.  Token'ı kopyalayın.

## 3. Jenkins Credentials Ayarları

Jenkins ana sayfasına gidin -> **Manage Jenkins** -> **Manage Credentials** -> **System** -> **Global credentials (unrestricted)** -> **Add Credentials**.

Aşağıdaki 3 anahtarı tanımlayın:

### A. GitLab Erişimi
*   **Kind:** Username with password
*   **Username:** `root` (GitLab kullanıcınız)
*   **Password:** GitLab'dan aldığınız Access Token (ilk adımdaki).
*   **ID:** `gitlab-user-password` (Pipeline kodunda bu ID'yi kullanacağız).

### B. Docker Hub Erişimi
*   **Kind:** Username with password
*   **Username:** Docker Hub Kullanıcı Adınız (Örn: `kocakabdussamed`)
*   **Password:** Docker Hub'dan aldığınız PAT.
*   **ID:** `dockerhub-pat`

### C. Deploy Sunucusu Erişimi (SSH)
Deploy yapacağımız sunucu (Örn: `192.168.64.4` - SBR-3) için SSH bilgilerini girelim.
*   **Kind:** Username with password
*   **Username:** `root` (veya sunucu kullanıcısı)
*   **Password:** Sunucunun root şifresi.
*   **ID:** `sbr-3-ssh`

## 4. Projeleri Oluşturma (Import)

Size verilen örnek projeleri (`frontend` ve `backend`) GitLab'a yükleyin.
1.  GitLab'da **New Project** -> **Create blank project**.
2.  Proje Adı: `frontend`
3.  Aynı işlemi `backend` için de yapın.
4.  Lokaldeki proje kodlarını GitLab'a push'layın (`git remote add origin ...`).

Artık Jenkins'in kullanacağı anahtarlar ve kodlar hazır. Pipeline yazmaya başlayabiliriz.
