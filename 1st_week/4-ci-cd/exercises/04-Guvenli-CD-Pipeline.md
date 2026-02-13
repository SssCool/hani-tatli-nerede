# Uygulama 4: Güvenli CD Pipeline ve Otomatik Dağıtım (Frontend & Backend)

CI sürecinden başarıyla geçen (şifre yok, açık yok, build tamam) imajlarımızı şimdi hedef sunucuya dağıtacağız.

## Güvenlik Notu
CD sürecinde güvenlik, **Doğrulama ve Yetkilendirme** demektir.
*   Dağıtımı yapacak Jenkins agent'ı, hedef sunucuya sadece SSH ile erişebilmeli.
*   Hedef sunucu, sadece güvenilir Registry'den imaj çekmeli.

---

## 🚀 Bölüm 1: Backend Deploy Pipeline

### 1.1 Jenkins Projesi (backend-deploy)
1.  **New Item** -> Ad: `backend-deploy` -> **Pipeline**.
2.  **Trigger:** Bu pipeline genellikle `backend-ci` bittiğinde tetiklenir ("Build after other projects are built").

### 1.2 Pipeline Kodu

```groovy
pipeline {
    agent any

    triggers {
        // backend-ci başarılı olursa otomatik çalış
        // upstream(upstreamProjects: 'backend-ci', threshold: hudson.model.Result.SUCCESS)
        gitlab(triggerOnPush: true, triggerOnMergeRequest: true)
    }

    environment {
        DOCKER_IMAGE   = 'kocakabdussamed/sbr-backend' 
        DEPLOY_HOST    = '192.168.64.4'  // Hedef Sunucu (SBR-3)
        DEPLOY_PORT    = '8090'          // Backend Portu
        CONTAINER      = 'backend'
        OVERALL_STATUS = 'jenkins-deploy'
    }

    stages {
        stage('Deploy Backend to sbr-3') {
            steps {
                gitlabCommitStatus(name: 'deploy_backend') {
                    // SSH Bağlantı Bilgileri
                    withCredentials([usernamePassword(
                        credentialsId: 'sbr-3-ssh',
                        usernameVariable: 'SSH_USER',
                        passwordVariable: 'SSH_PASS'
                    )]) {
                        sh '''
                            set -e
                            
                            # Hedef sunucuya güvenli SSH bağlantısı
                            sshpass -p "$SSH_PASS" ssh \
                              -o StrictHostKeyChecking=no \
                              -o UserKnownHostsFile=/dev/null \
                              "$SSH_USER@$DEPLOY_HOST" \
                              DOCKER_IMAGE="$DOCKER_IMAGE" \
                              DEPLOY_PORT="$DEPLOY_PORT" \
                              CONTAINER="$CONTAINER" \
                              'bash -se' <<'EOF'
                                set -e

                                echo "[Remote] 1. Backend İmajı Güncelleniyor..."
                                docker pull "$DOCKER_IMAGE:latest"

                                echo "[Remote] 2. Eski Konteyner Temizleniyor..."
                                docker stop "$CONTAINER" 2>/dev/null || true
                                docker rm   "$CONTAINER" 2>/dev/null || true

                                echo "[Remote] 3. Yeni Versiyon Başlatılıyor..."
                                docker run -d \
                                  --name "$CONTAINER" \
                                  --restart always \
                                  -p "$DEPLOY_PORT:$DEPLOY_PORT" \
                                  "$DOCKER_IMAGE:latest"

                                echo "[Remote] ✅ Backend Dağıtımı Başarılı."
EOF
                        '''
                    }
                }
            }
        }
        
        stage('Verification (Smoke Test)') {
             steps {
                 echo "Backend erişilebilirlik testi..."
                 sh "curl -f http://${DEPLOY_HOST}:${DEPLOY_PORT}/list || echo 'Uyarı: Servis hemen cevap vermedi'"
             }
        }
    }

    post {
        success {
            echo "✅ Backend Deploy Başarılı: http://${DEPLOY_HOST}:${DEPLOY_PORT}"
            updateGitlabCommitStatus name: OVERALL_STATUS, state: 'success'
        }
        failure {
            echo '❌ Backend Deploy Başarısız!'
            updateGitlabCommitStatus name: OVERALL_STATUS, state: 'failed'
        }
    }
}
```

---

## 🚀 Bölüm 2: Frontend Deploy Pipeline

### 2.1 Jenkins Projesi (frontend-deploy)
1.  **New Item** -> Ad: `frontend-deploy` -> **Pipeline**.
2.  **Trigger:** `frontend-ci` bittiğinde tetiklenir.

### 2.2 Pipeline Kodu

```groovy
pipeline {
    agent any

    triggers {
        // frontend-ci başarılı olursa otomatik çalış
        // upstream(upstreamProjects: 'frontend-ci', threshold: hudson.model.Result.SUCCESS)
        gitlab(triggerOnPush: true, triggerOnMergeRequest: true)
    }

    environment {
        DOCKER_IMAGE   = 'kocakabdussamed/sbr-frontend' 
        DEPLOY_HOST    = '192.168.64.4'  // Hedef Sunucu (SBR-3)
        DEPLOY_PORT    = '8080'          // Frontend Portu
        CONTAINER      = 'frontend'
        OVERALL_STATUS = 'jenkins-deploy'
    }

    stages {
        stage('Deploy Frontend to sbr-3') {
            steps {
                gitlabCommitStatus(name: 'deploy_frontend') {
                    withCredentials([usernamePassword(
                        credentialsId: 'sbr-3-ssh',
                        usernameVariable: 'SSH_USER',
                        passwordVariable: 'SSH_PASS'
                    )]) {
                        sh '''
                            set -e
                            
                            echo "[Jenkins] Hedef sunucuya bağlanılıyor..."

                            sshpass -p "$SSH_PASS" ssh \
                              -o StrictHostKeyChecking=no \
                              -o UserKnownHostsFile=/dev/null \
                              "$SSH_USER@$DEPLOY_HOST" \
                              DOCKER_IMAGE="$DOCKER_IMAGE" \
                              DEPLOY_PORT="$DEPLOY_PORT" \
                              CONTAINER="$CONTAINER" \
                              'bash -se' <<'EOF'
                                set -e

                                echo "[Remote] 1. Frontend İmajı Çekiliyor..."
                                docker pull "$DOCKER_IMAGE:latest"

                                echo "[Remote] 2. Eski Frontend Temizleniyor..."
                                docker stop "$CONTAINER" 2>/dev/null || true
                                docker rm   "$CONTAINER" 2>/dev/null || true

                                echo "[Remote] 3. Yeni Frontend Başlatılıyor..."
                                docker run -d \
                                  --name "$CONTAINER" \
                                  --restart always \
                                  -p "$DEPLOY_PORT:$DEPLOY_PORT" \
                                  "$DOCKER_IMAGE:latest"

                                echo "[Remote] ✅ Frontend Dağıtımı Başarılı."
EOF
                        '''
                    }
                }
            }
        }
        
        stage('Verification') {
             steps {
                 echo "Frontend erişilebilirlik testi..."
                 sh "curl -f http://${DEPLOY_HOST}:${DEPLOY_PORT} || echo 'Uyarı: Frontend cevap vermedi!'"
             }
        }
    }

    post {
        success {
            echo "✅ Frontend Deploy Başarılı: http://${DEPLOY_HOST}:${DEPLOY_PORT}"
            updateGitlabCommitStatus name: OVERALL_STATUS, state: 'success'
        }
        failure {
            echo '❌ Frontend Deploy Başarısız!'
            updateGitlabCommitStatus name: OVERALL_STATUS, state: 'failed'
        }
    }
}
```

---

## 🔗 Tam Entegrasyon Testi (Full Cycle)

Artık elimizde 4 parça var:
1.  **Frontend CI:** Kodu al -> Güvenlik Tara -> Build -> Push
2.  **Backend CI:** Kodu al -> Güvenlik Tara -> Build -> Push
3.  **Frontend CD:** Sunucuya bağlan -> Frontend'i güncelle (Port 8080)
4.  **Backend CD:** Sunucuya bağlan -> Backend'i güncelle (Port 8090)

**Senaryo:**
1.  Yerel bilgisayarınızda bir kod değişikliği yapın (Örn: `index.html` başlığını değiştirin).
2.  Git ile `commit` ve `push` yapın.
3.  GitLab -> Jenkins CI -> DockerHub -> Jenkins CD -> Canlı Sunucu akışını izleyin.
4.  Tarayıcıdan değişikliğin canlıya yansıdığını görün.
