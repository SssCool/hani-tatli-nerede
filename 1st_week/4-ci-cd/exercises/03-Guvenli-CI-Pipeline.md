# Uygulama 3: Güvenli CI Pipeline (Frontend & Backend)

Bu bölümde, hem `frontend` hem de `backend` projelerimiz için **DevSecOps** prensiplerine uygun, güvenlik taramalı CI pipeline'ları kuracağız.

## Araçlar ve Referanslar
Pipeline içerisinde kullanacağımız güvenlik araçları şunlardır:
*   **TruffleHog:** Şifre ve Secret taraması.
    *   *Repo:* [https://github.com/trufflesecurity/trufflehog](https://github.com/trufflesecurity/trufflehog)
*   **Semgrep:** Statik Kod Analizi (SAST).
    *   *Repo:* [https://github.com/returntocorp/semgrep](https://github.com/returntocorp/semgrep)

---

## 🚀 Bölüm 1: Frontend Güvenli CI

### 1.1 Jenkins Projesi (frontend-ci)
1.  **New Item** -> Ad: `frontend-ci` -> **Pipeline**.
2.  **Build Triggers** -> **Build when a change is pushed to GitLab**.
3.  **Pipeline Script**:

```groovy
pipeline {
    agent any

    triggers {
        gitlab(triggerOnPush: true, triggerOnMergeRequest: true)
    }

    environment {
        DOCKER_IMAGE   = 'kocakabdussamed/sbr-frontend' // Kendi kullanıcı adınızı yazın
        DOCKER_TAG     = "${BUILD_NUMBER}"
        OVERALL_STATUS = 'jenkins-ci'
        HOST_WORKSPACE = "/var/jenkins_home/workspace/${env.JOB_NAME}"
    }

    stages {
        stage('Clone Code') {
            steps {
                script {
                    updateGitlabCommitStatus name: OVERALL_STATUS, state: 'running'
                    /* Kendi GitLab IPnizi yazın */
                    gitlabCommitStatus(name: 'clone') {
                        git branch: 'main',
                            url: 'http://192.168.64.2/root/frontend.git',
                            credentialsId: 'gitlab-user-password'
                    }
                }
            }
        }

        stage('Security Scans') {
            parallel {
                stage('Secret Scan (TruffleHog)') {
                    steps {
                        script {
                            gitlabCommitStatus(name: 'trufflehog') {
                                // --fail: Secret bulursa build patlasın
                                sh "docker run --rm -v ${HOST_WORKSPACE}:/pwd trufflesecurity/trufflehog:latest filesystem /pwd --fail --no-update"
                            }
                        }
                    }
                }

                stage('SAST Scan (Semgrep)') {
                    steps {
                        script {
                            gitlabCommitStatus(name: 'semgrep') {
                                // --error: Kritik kod hatası bulursa build patlasın
                                sh "docker run --rm -v ${HOST_WORKSPACE}:/src returntocorp/semgrep semgrep scan --config=auto --severity ERROR --error"
                            }
                        }
                    }
                }
            }
        }

        stage('Build Docker Image') {
            steps {
                script {
                    gitlabCommitStatus(name: 'docker_build') {
                        sh "docker build -t ${DOCKER_IMAGE}:${DOCKER_TAG} -t ${DOCKER_IMAGE}:latest ."
                    }
                }
            }
        }

        stage('Push to Docker Hub') {
            steps {
                script {
                    gitlabCommitStatus(name: 'docker_push') {
                        withCredentials([usernamePassword(credentialsId: 'dockerhub-pat', usernameVariable: 'DOCKER_USER', passwordVariable: 'DOCKER_PASS')]) {
                            sh '''
                                echo "$DOCKER_PASS" | docker login -u "$DOCKER_USER" --password-stdin
                                docker push "${DOCKER_IMAGE}:${DOCKER_TAG}"
                                docker push "${DOCKER_IMAGE}:latest"
                            '''
                        }
                    }
                }
            }
        }
    }

    post {
        success {
            echo "✅ Frontend CI Başarılı"
            updateGitlabCommitStatus name: OVERALL_STATUS, state: 'success'
        }
        failure {
            echo "❌ Pipeline Başarısız!"
            updateGitlabCommitStatus name: OVERALL_STATUS, state: 'failed'
        }
        always {
            sh "docker rmi ${DOCKER_IMAGE}:${DOCKER_TAG} 2>/dev/null || true"
            sh "docker rmi ${DOCKER_IMAGE}:latest 2>/dev/null || true"
        }
    }
}
```

---

## 🚀 Bölüm 2: Backend Güvenli CI

Backend projesi veritabanı işlemleri yaptığı için güvenliği daha kritiktir.

### 2.1 Jenkins Projesi (backend-ci)
1.  **New Item** -> Ad: `backend-ci` -> **Pipeline**.
2.  **Trigger:** GitLab Push events.
3.  **Pipeline Script**:

```groovy
pipeline {
    agent any

    triggers {
        gitlab(triggerOnPush: true, triggerOnMergeRequest: true)
    }

    environment {
        // Backend İmaj Adınız
        DOCKER_IMAGE   = 'kocakabdussamed/sbr-backend' 
        DOCKER_TAG     = "${BUILD_NUMBER}"
        OVERALL_STATUS = 'jenkins-ci'
        HOST_WORKSPACE = "/var/jenkins_home/workspace/${env.JOB_NAME}"
    }

    stages {
        stage('Clone Code') {
            steps {
                script {
                    updateGitlabCommitStatus name: OVERALL_STATUS, state: 'running'
                    gitlabCommitStatus(name: 'clone') {
                        git branch: 'main',
                            url: 'http://192.168.64.2/root/backend.git',
                            credentialsId: 'gitlab-user-password'
                    }
                }
            }
        }

        stage('Security Scans') {
            parallel {
                stage('Secret Scan (TruffleHog)') {
                    steps {
                        script {
                            gitlabCommitStatus(name: 'trufflehog') {
                                sh "docker run --rm -v ${HOST_WORKSPACE}:/pwd trufflesecurity/trufflehog:latest filesystem /pwd --fail --no-update"
                            }
                        }
                    }
                }

                stage('SAST Scan (Semgrep)') {
                    steps {
                        script {
                            gitlabCommitStatus(name: 'semgrep') {
                                // Backend özelinde Python kurallarını zorlayabiliriz
                                sh "docker run --rm -v ${HOST_WORKSPACE}:/src returntocorp/semgrep semgrep scan --config=p/python --severity ERROR --error"
                            }
                        }
                    }
                }
            }
        }

        stage('Build Docker Image') {
            steps {
                script {
                    gitlabCommitStatus(name: 'docker_build') {
                        sh "docker build -t ${DOCKER_IMAGE}:${DOCKER_TAG} -t ${DOCKER_IMAGE}:latest ."
                    }
                }
            }
        }

        stage('Push to Docker Hub') {
            steps {
                script {
                    gitlabCommitStatus(name: 'docker_push') {
                        withCredentials([usernamePassword(credentialsId: 'dockerhub-pat', usernameVariable: 'DOCKER_USER', passwordVariable: 'DOCKER_PASS')]) {
                            sh '''
                                echo "$DOCKER_PASS" | docker login -u "$DOCKER_USER" --password-stdin
                                docker push "${DOCKER_IMAGE}:${DOCKER_TAG}"
                                docker push "${DOCKER_IMAGE}:latest"
                            '''
                        }
                    }
                }
            }
        }
    }

    post {
        success {
            echo "✅ Backend CI Başarılı -> CD Tetiklenebilir"
            updateGitlabCommitStatus name: OVERALL_STATUS, state: 'success'
            
            // Eğer CD pipeline'ını da otomatik çalıştırmak isterseniz:
            // build job: 'backend-deploy', wait: false
        }
        failure {
            echo "❌ Backend Pipeline Başarısız!"
            updateGitlabCommitStatus name: OVERALL_STATUS, state: 'failed'
        }
        always {
            sh "docker rmi ${DOCKER_IMAGE}:${DOCKER_TAG} 2>/dev/null || true"
            sh "docker rmi ${DOCKER_IMAGE}:latest 2>/dev/null || true"
        }
    }
}
```
