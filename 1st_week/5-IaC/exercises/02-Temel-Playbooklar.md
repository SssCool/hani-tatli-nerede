# Uygulama 2: Temel Playbooklar

Envanterimiz hazır. Şimdi sunuculara iş yaptırmak için senaryolar (Playbook) yazacağız. Playbooklar `.yml` formatındadır.

Dosyaları `playbooks/` altına kaydedin. Çalıştırırken proje ana dizininden:
`ansible-playbook playbooks/dosya_adi.yml` komutunu kullanacağız.

---

## A. Sunucu Hazırlığı (`01-base-setup.yml`)
Tüm sunucularda temel paketlerin yüklü olduğundan emin olalım.

```yaml
---
- name: Temel Sunucu Hazırlığı
  hosts: all                       # Tüm sunucularda çalışsın
  tasks:
    - name: Paket Listesini Güncelle (apt-get update)
      apt:                         # Ubuntu/Debian modülü
        update_cache: yes
      when: ansible_os_family == "Debian" # Sadece Debian tabanlıysa çalıştır

    - name: Gerekli Paketleri Yükle
      package:                     # 'package' modülü hem apt hem yum destekler (generic)
        name: "{{ item }}"         # Döngüden gelen eleman
        state: present             # Yüklü olsun
      loop:                        # Liste elemanları
        - git
        - curl
        - wget
        - htop
        - unzip
        - net-tools
        - vim
        - sshpass
```
**Çalıştır:** `ansible-playbook playbooks/01-base-setup.yml`

---

## B. Kullanıcı Oluşturma (`02-create-user.yml`)
`group_vars` dosyasında tanımladığımız `new_user` değişkenini kullanarak yeni bir kullanıcı açacağız.

```yaml
---
- name: Kullanıcı Oluşturma
  hosts: all
  tasks:
    - name: Kullanıcıyı Ekle
      user:
        name: "{{ new_user }}"     # Değişken kullanımı
        # Şifreler Linux'ta hashlenmelidir. Ansible filtreleri ile bunu yapıyoruz.
        password: "{{ plain_pass | password_hash('sha512') }}"
        shell: /bin/bash
        groups: sudo               # Sudo yetkisi ver
        append: yes                # Mevcut gruplarını silme
        state: present
```
**Çalıştır:** `ansible-playbook playbooks/02-create-user.yml`
*Test:* Sunucuya gidip `grep devops /etc/passwd` ile kontrol edebilirsiniz.

---

## C. Docker Konteyneri Başlatma (`03-deploy-container.yml`)
Sadece `docker_servers` grubunda çalışacak bir görev.

```yaml
---
- name: Web Sunucusu Konteyneri
  hosts: docker_servers            # HEDEF: Sadece Docker sunucuları
  tasks:
    - name: Python Docker SDK Yükle (Ansible için gerekli)
      apt:
        name: python3-docker
        state: present
      ignore_errors: yes           # Zaten varsa hata verme

    - name: Nginx Konteynerini Başlat
      docker_container:            # Docker modülü
        name: my-web-server
        image: nginx:latest
        state: started
        restart_policy: always
        ports:
          - "8081:80"              # Host 8081 -> Container 80
```
**Çalıştır:** `ansible-playbook playbooks/03-deploy-container.yml`
*Test:* Tarayıcıdan `http://192.168.64.4:8081` adresine gidin. Nginx sayfasını görmelisiniz.
