# Versiyon Kontrol Sistemleri (VCS) ve Git Temelleri: Derinlemesine Bakış

## 1. Git Mimarisi ve Çalışma Mantığı
Git, dağıtık (distributed) bir versiyon kontrol sistemidir. Yani her kullanıcının bilgisayarında projenin **tam tarihçesi** bulunur.

### Git'in Üç Aşaması (The Three Stages)
Git'te bir dosya yaşam döngüsü boyunca üç alandan geçer:

**Akış Şeması:**
`Working Directory` --(git add)--> `Staging Area` --(git commit)--> `Local Repository` --(git push)--> `Remote Repository`

1.  **Working Directory (Çalışma Masası):** Şu an üzerinde çalıştığınız, düzenlediğiniz dosyalar.
2.  **Staging Area (Kargo Masası):** Commitlemeye hazırladığınız dosyalar. `git add` ile dosyaları buraya koyarsınız.
3.  **Local Repository (Kasa/Arşiv):** `git commit` dediğinizde paket mühürlenir ve güvenli veritabanına (`.git`) işlenir.

---

## 2. Git Konfigürasyonu (Scopes)
Git ayarları üç seviyede tutulur:
1.  **System:** Tüm kullanıcılar için (`/etc/gitconfig`).
2.  **Global:** Sizin kullanıcınız için (`~/.gitconfig`).
3.  **Local:** Sadece o proje için (`.git/config`).

```bash
# Öncelik sırası: Local > Global > System
git config --global user.name "Ad Soyad"
git config --global user.email "mail@pol.tr"
git config --global core.editor "vim"
git config --list  # Tüm ayarları gör
```

---

## 3. .gitignore Dosyası
Bazı dosyaların (şifreler, loglar, derlenmiş .exe dosyaları) repoya girmesini **asla** istemeyiz.

```gitignore
# .gitignore Örneği
*.log       # Tüm log dosyalarını yoksay
node_modules/ # node_modules klasörünü yoksay
.env        # Şifrelerin olduğu dosyayı ASLA atma!
dist/       # Build çıktılarını yoksay
```

---

## 4. Dosya Durumlarını Anlamak (File/Lifecycle Status)
Dosyalar 4 durumda olabilir:
*   **Untracked:** Git'in haberi yok (Yeni dosya).
*   **Unmodified:** Değişiklik yok, son commit ile aynı.
*   **Modified:** Dosya değiştirilmiş ama henüz staging'e alınmamış.
*   **Staged:** Dosya değiştirilmiş ve commitlenmeye hazır.

```bash
git status -s  # Kısa özet (M: Modified, A: Added, ??: Untracked)
```

## 5. Farkları İncelemek (Diffing)
*   `git diff`: Working Directory ile Staging arasındaki farkı gösterir (Henüz `add` demediklerim).
*   `git diff --staged`: Staging ile son Commit arasındaki farkı gösterir (Commitlenecekler).
