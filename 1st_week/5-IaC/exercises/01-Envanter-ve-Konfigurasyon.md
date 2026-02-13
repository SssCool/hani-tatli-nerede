# Uygulama 1: Konfigürasyon ve Envanter Yönetimi

Ansible'ın beyni `ansible.cfg` ve haritası `inventory` dosyalarıdır. Bu laboratuvarda, `ansible-examples` klasöründeki yapıyı inceleyerek kendi ortamımızı kuracağız.

## 1. Hazırlık
Çalışma dizininizde (`devops-lab` veya `1st_week/ansible/exercises/lab`) şu yapıyı oluşturun:

```bash
mkdir -p my-ansible/inventory/group_vars
mkdir -p my-ansible/roles/webapp/{tasks,handlers,files}
mkdir -p my-ansible/playbooks
mkdir -p my-ansible/backups
cd my-ansible
```

**Hedeflenen Klasör Yapısı:**
```text
my-ansible/
├── ansible.cfg                 # (Dosya)
├── inventory/
│   ├── hosts.yml               # (Dosya)
│   └── group_vars/
│       └── all.yml             # (Dosya)
├── playbooks/
│   ├── 01-base-setup.yml
│   ├── 02-create-user.yml
│   └── ...
├── roles/
│   └── webapp/
│       ├── tasks/
│       │   └── main.yml
│       ├── handlers/
│       │   └── main.yml
│       └── files/
│           └── index.html
└── backups/                    # (Logların geleceği yer)
```

## 2. Konfigürasyon Dosyası (`ansible.cfg`)
Ansible'ın varsayılan davranışlarını belirleriz. Proje kök dizininde (`my-ansible/ansible.cfg`) oluşturun:

```ini
[defaults]
# Envanter dosyamızın yolunu belirtiyoruz.
inventory = ./inventory/hosts.yml
# Rollerin nerede olduğunu belirtiyoruz.
roles_path = ./roles
# SSH ile bağlanırken "Are you sure?" sorusunu sormasın (Otomasyon için kritik).
host_key_checking = False
# Sunuculara varsayılan olarak hangi kullanıcı ile bağlanılacak?
remote_user = root
# Şifre sorma (SSH key veya group_vars ile çözeceğiz).
ask_pass = False
# Python sürüm uyarısı vermesin (Kozmetik).
interpreter_python = auto_silent

[privilege_escalation]
# "sudo" yapma yetkisini aç (Eğer root değil normal user ile bağlanıyorsanız).
become = True
become_method = sudo
become_user = root
become_ask_pass = False
```

## 3. Envanter Dosyası (`inventory/hosts.yml`)
Yöneteceğimiz sunucuları gruplara ayırırız. YAML formatı okuması en kolay formattır.

```yaml
---
all:
  children:
    # Jenkins ve CI/CD makineleri grubu
    jenkins_servers:
      hosts:
        # Kendi Jenkins sunucunuzun IP'sini yazın (Lab ortamı)
        192.168.64.3:
        
    # Uygulama sunucuları grubu
    docker_servers:
      hosts:
        # Kendi Deploy sunucunuzun IP'sini yazın
        192.168.64.4:
        
    # 'production' üst grubu, yukarıdaki iki grubu da kapsar
    production:
      children:
        jenkins_servers:
        docker_servers:
```

## 4. Değişkenler (`inventory/group_vars/all.yml`)
Tüm sunucular (`all`) veya belirli gruplar için ortak değişkenler tanımlarız. Şifreleri burada tutabiliriz (Prod ortamında Ansible Vault ile şifrelenmelidir, eğitim için açık yazıyoruz).

```yaml
---
# SSH Bağlantı Ayarları
ansible_user: root
ansible_password: "sizin_root_sifreniz"  # Burayı güncelleyin!
ansible_connection: ssh
ansible_port: 22

# Bizim tanımladığımız özel değişkenler (Playbooklarda kullanacağız)
new_user: devops_admin
plain_pass: "GuvenliSifre123!"
```

## 5. Doğrulama (Ping Testi)
Konfigürasyonun doğru çalıştığını test etmek için **ad-hoc** komut kullanacağız. `ping` modülü sunucuya bağlanıp "pong" cevabı döner.

```bash
# Tüm sunuculara ping at
ansible all -m ping

# Sadece docker sunucularına ping at
ansible docker_servers -m ping
```
*Başarılı (Yeşil) çıktı alıyorsanız bağlantı tamam demektir.*
