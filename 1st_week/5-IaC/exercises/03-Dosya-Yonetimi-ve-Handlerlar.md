# Uygulama 3: Dosya Yönetimi ve Handlerlar

Bu bölümde Ansible'ın güçlü özelliklerinden olan "Dosya Transferi" (Fetch/Copy) ve "Tetikleyiciler" (Handlers) konularını işleyeceğiz.

---

## A. Log Toplama - Forensic (`04-collect-logs.yml`)
Bir siber olay anında, tüm sunuculardan logları tek bir merkeze (sizin bilgisayarınıza) çekmek için kullanılır. `fetch` modülü "Remote -> Local" çalışır.

```yaml
---
- name: Log Toplama ve Yedekleme
  hosts: all
  tasks:
    - name: Auth Log Dosyasını Çek
      fetch:
        src: /var/log/auth.log     # Uzaktaki dosya
        # Kaydedilecek yer (Otomatik klasör açar)
        # inventory_hostname: O an işlem yapılan sunucunun adı/IP'si
        dest: backups/{{ inventory_hostname }}/auth.log 
        flat: yes                  # Klasör ağacını kopyalama, sadece dosyayı al
      ignore_errors: yes           # Dosya yoksa durma, devam et

    - name: Syslog Dosyasını Çek
      fetch:
        src: /var/log/syslog
        dest: backups/{{ inventory_hostname }}/syslog
        flat: yes
```
**Çalıştır:** `ansible-playbook playbooks/04-collect-logs.yml`
**Sonuç:** Proje klasörünüzde `backups/192.168.64.4/auth.log` gibi dosyalar oluşacaktır.

---

## B. Handler Mantığı (`05-simple-handler.yml`)
Ansible'da bazı işlemlerin **sadece değişiklik olduğunda** yapılması istenir. Örneğin: Konfigürasyon değişirse servisi restart et, değişmezse dokunma. Bunu `notify` ve `handlers` ile yaparız.

```yaml
---
- name: SSH Banner Konfigürasyonu
  hosts: all
  tasks:
    - name: SSH Banner Mesajını Değiştir
      copy:
        content: "UYARI: Bu sisteme giris izlenmektedir!\n"
        dest: /etc/issue.net
      notify: Restart SSH          # <-- Tetikleyici! EĞER dosya değişirse 'Restart SSH'i çağır.

  handlers:                        # <-- Handlerlar, tüm tasklar bitince en sonda çalışır.
    - name: Restart SSH
      service:
        name: sshd
        state: restarted
```
**Test:**
1.  Playbook'u ilk çalıştırdığınızda dosya değişeceği için `Restart SSH` çalışır (**Changed**).
2.  Playbook'u ikinci kez çalıştırdığınızda dosya aynı olduğu için `Restart SSH` ÇALIŞMAZ (**Ok**). Buna **Idempotency** (Tekrarlanabilirlik) denir. Ansible'ın en önemli özelliğidir.
