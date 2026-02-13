# Uygulama 4: Roller ve İleri Seviye Kullanım

Playbooklar büyüdükçe yönetilmesi zorlaşır. Ansible **Roles** (Roller) yapısı ile kodunuzu modüllere bölmenizi sağlar. Bir rol; taskları, dosyaları, değişkenleri ve handlerları içeren bağımsız bir pakettir.

## A. Rol Yapısı
`roles/webapp/` klasörü altında şu yapıyı oluşturun:
(`mkdir -p roles/webapp/{tasks,files,handlers}`)

1.  **`roles/webapp/tasks/main.yml`** (Rolün ne iş yapacağı):
    ```yaml
    ---
    - name: Nginx Paketini Yükle
      package:
        name: nginx
        state: present

    - name: Özel Index Dosyasını Kopyala
      copy:
        src: index.html       # 'files' klasörüne bakacağını bilir
        dest: /var/www/html/index.html
        mode: '0644'
      notify: Restart Nginx   # Handler tetikle

    - name: Nginx Servisini Başlat
      service:
        name: nginx
        state: started
        enabled: yes
    ```

2.  **`roles/webapp/handlers/main.yml`** (Rolün handlerları):
    ```yaml
    ---
    - name: Restart Nginx
      service:
        name: nginx
        state: restarted
    ```

3.  **`roles/webapp/files/index.html`** (Kopyalanacak dosya):
    ```html
    <h1>Merhaba Ansible Roles!</h1>
    <p>Bu dosya Ansible tarafindan dagitildi.</p>
    ```

## B. Rolü Çağırma (`07-role-deployment.yml`)
Rol hazırlandıktan sonra onu kullanmak tek bir satırdır.

```yaml
---
- name: Web Uygulaması Dağıtımı (Role ile)
  hosts: docker_servers
  roles:
    - webapp              # roles/webapp klasörünü bulur ve her şeyi otomatik yapar
```
**Çalıştır:** `ansible-playbook playbooks/07-role-deployment.yml`

---

## C. İleri Seviye: Tarihli Backup (`08-backup-advanced.yml`)
Değişken kaydetme (`register`) kullanarak dinamik isimlendirme yapalım.

```yaml
---
- name: Gelişmiş Yedekleme
  hosts: all
  vars:
    backup_dir: /tmp/ansible_backups
    
  tasks:
    - name: Tarih Bilgisini Al (Linux komutu)
      command: date +%Y-%m-%d
      register: current_date       # <-- Çıktıyı değişkene kaydettik

    - name: Yedeklenecek Klasörü Sıkıştır
      archive:
        path: /var/log
        # Değişkeni kullanıyoruz: logs_2024-10-10.tar.gz
        dest: "{{ backup_dir }}/logs_{{ current_date.stdout }}.tar.gz"
        format: gz
      
    - name: Yedeği Local'e İndir
      fetch:
        src: "{{ backup_dir }}/logs_{{ current_date.stdout }}.tar.gz"
        dest: "backups/{{ inventory_hostname }}/"
        flat: yes
```

## D. İleri Seviye: Döngüler (`09-users-advanced.yml`)
Tek seferde farklı özelliklere sahip kullanıcılar açmak.

```yaml
---
- name: Toplu Kullanıcı Yönetimi
  hosts: all
  tasks:
    - name: Kullanıcıları Oluştur
      user:
        name: "{{ item.name }}"
        group: "{{ item.group }}"
        shell: "{{ item.shell }}"
        state: present
      loop:
        - { name: 'ali', group: 'sudo', shell: '/bin/bash' }
        - { name: 'veli', group: 'nogroup', shell: '/bin/sh' }
        - { name: 'ayse', group: 'root', shell: '/bin/zsh' }
```
Bu yöntemle yüzlerce kullanıcıyı tek bir task ile yönetebilirsiniz.
