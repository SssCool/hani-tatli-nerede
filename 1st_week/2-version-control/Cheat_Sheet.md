# Git Profesyonel Komut Kartı (Advanced Cheat Sheet)

## ⚡️ Temel Komutlar
| Komut | Açıklama |
|---|---|
| `git init` | Repoyu başlat. |
| `git clone <url>` | Repoyu indir. |
| `git status` | Durumu göster (Hangi dosyalar değişti?). |
| `git add .` | Tüm değişiklikleri sahneye (stage) al. |
| `git commit -m "msg"` | Değişiklikleri kaydet. |
| `git push origin main` | Sunucuya gönder. |
| `git pull` | Sunucudan hem çek hem birleştir (Fetch + Merge). |

## 🌴 Branch (Dal) Yönetimi
| Komut | Açıklama |
|---|---|
| `git branch` | Dalları listele. |
| `git branch -a` | Uzak (remote) dallar dahil hepsini listele. |
| `git checkout -b <name>` | Yeni dal oluştur ve geç. |
| `git switch <name>` | Dala geçiş yap (Modern komut). |
| `git branch -d <name>` | Dalı sil (Lokal). |
| `git push origin --delete <name>` | Dalı sil (Uzak sunucudan). |

## ↩️ Geri Alma (Undo) & Düzeltme
| Komut | Açıklama |
|---|---|
| `git checkout -- <file>` | Dosyadaki değişiklikleri iptal et (Son commite dön). |
| `git restore <file>` | Dosyayı geri yükle (Modern komut). |
| `git reset --soft HEAD~1` | Son commiti geri al ama **değişiklikleri koru** (Staging'e at). |
| `git reset --hard HEAD~1` | Son commiti ve **her şeyi sil** (Tehlikeli!). |
| `git commit --amend` | Son commiti düzenle (Mesajı değiştir veya dosya ekle). |
| `git revert <commit_id>` | Eski bir commiti **tersine çeviren** yeni bir commit at (Güvenli geri alma). |

## 🕵️‍♂️ İnceleme & Log
| Komut | Açıklama |
|---|---|
| `git log --oneline --graph` | Tarihçeyi grafik ve tek satır olarak göster. |
| `git diff` | Working directory ile Staging farkını gör. |
| `git blame <file>` | Dosyanın hangi satırını, kimin, ne zaman değiştirdiğini gör (Suçluyu bul!). |

## 🚀 İleri Seviye (Advanced)
| Komut | Açıklama |
|---|---|
| `git stash` | Değişiklikleri geçici olarak rafa kaldır (Branch değiştirmek için). |
| `git stash pop` | Raftaki değişiklikleri geri yükle. |
| `git cherry-pick <commit_id>` | Başka bir daldan **sadece tek bir commiti** cımbızla alıp buraya getir. |
| `git rebase main` | Bulunduğun dalın başlangıç noktasını main'in ucuna taşı (Tarihçeyi düzelt). |
| `git rebase -i HEAD~3` | Son 3 commiti interaktif düzenle (Birleştir, sil, mesaj değiştir). |
| `git reflog` | Silinen commitler dahil **her hareketin** kaydını göster (Hayat kurtarır!). |
