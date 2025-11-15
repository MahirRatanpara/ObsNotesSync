# Complete DevOps Guide for SDE2 Interviews
*Comprehensive reference covering CI/CD, infrastructure, containerization, and deployment strategies*

## 📚 Table of Contents

1. [DevOps Fundamentals](#devops-fundamentals)
2. [Version Control and Git](#version-control-and-git)
3. [CI/CD Pipelines](#cicd-pipelines)
4. [Containerization](#containerization)
5. [Infrastructure as Code](#infrastructure-as-code)
6. [Monitoring and Observability](#monitoring-and-observability)
7. [Configuration Management](#configuration-management)
8. [Security (DevSecOps)](#security-devsecops)
9. [Cloud Platforms](#cloud-platforms)
10. [Deployment Strategies](#deployment-strategies)
11. [Performance and Scalability](#performance-and-scalability)
12. [Interview Questions](#interview-questions)

---

## ⚙️ DevOps Fundamentals

### DevOps Culture and Principles

| Principle | Description | Implementation |
|-----------|-------------|----------------|
| **Collaboration** | Break down silos between Dev and Ops | Cross-functional teams, shared tools |
| **Automation** | Automate repetitive tasks | CI/CD, infrastructure automation |
| **Continuous Improvement** | Iterative enhancement | Retrospectives, metrics-driven decisions |
| **Fast Feedback** | Quick detection of issues | Automated testing, monitoring |
| **Shared Responsibility** | Everyone owns quality | Shared on-call, pair programming |

### DevOps Lifecycle

```mermaid
graph LR
    A[Plan] --> B[Code]
    B --> C[Build]
    C --> D[Test]
    D --> E[Release]
    E --> F[Deploy]
    F --> G[Operate]
    G --> H[Monitor]
    H --> A
```

### Key Metrics

#### DORA Metrics (DevOps Research & Assessment)

| Metric | Elite | High | Medium | Low |
|--------|-------|------|--------|-----|
| **Lead Time** | < 1 hour | 1 day - 1 week | 1 week - 1 month | 1-6 months |
| **Deployment Frequency** | On-demand | 1x/day - 1x/week | 1x/week - 1x/month | < 1x/month |
| **Mean Time to Recovery** | < 1 hour | < 1 day | 1 day - 1 week | 1 week - 1 month |
| **Change Failure Rate** | 0-15% | 16-30% | 16-30% | 16-30% |

---

## 🔧 Version Control and Git

### Git Workflow Strategies

#### Git Flow

```bash
# Main branches
git checkout -b develop origin/main
git checkout -b release/1.0.0 develop
git checkout -b hotfix/1.0.1 main

# Feature branches
git checkout -b feature/user-authentication develop
git add .
git commit -m "feat: implement user login functionality"
git push origin feature/user-authentication

# Create pull request and merge
git checkout develop
git merge --no-ff feature/user-authentication
git branch -d feature/user-authentication
```

#### GitHub Flow (Simplified)

```bash
# Create feature branch
git checkout -b feature/api-enhancement
git push -u origin feature/api-enhancement

# Make changes and commit
git add .
git commit -m "Add rate limiting to API endpoints"
git push

# Create PR, review, and merge to main
# Deploy directly from main branch
```

### Advanced Git Techniques

#### Interactive Rebase for Clean History

```bash
# Squash commits before merging
git rebase -i HEAD~3

# In the editor:
# pick abc123 Add user model
# squash def456 Fix typo in user model  
# squash ghi789 Add user validation

# Result: Clean, single commit for the feature
```

#### Git Hooks for Quality Gates

```bash
#!/bin/sh
# .git/hooks/pre-commit

# Run tests before allowing commit
echo "Running tests..."
npm test
if [ $? -ne 0 ]; then
    echo "Tests failed. Commit aborted."
    exit 1
fi

# Run linting
echo "Running linter..."
npm run lint
if [ $? -ne 0 ]; then
    echo "Linting failed. Commit aborted."
    exit 1
fi

echo "Pre-commit checks passed!"
```

---

## 🚀 CI/CD Pipelines

### Jenkins Pipeline as Code

```groovy
pipeline {
    agent any
    
    environment {
        DOCKER_REGISTRY = 'your-registry.com'
        APP_NAME = 'user-service'
        KUBECONFIG = credentials('kubeconfig')
    }
    
    stages {
        stage('Checkout') {
            steps {
                git branch: 'main', url: 'https://github.com/company/user-service'
            }
        }
        
        stage('Build') {
            steps {
                script {
                    sh './gradlew clean build'
                    
                    // Archive artifacts
                    archiveArtifacts artifacts: 'build/libs/*.jar'
                }
            }
        }
        
        stage('Test') {
            parallel {
                stage('Unit Tests') {
                    steps {
                        sh './gradlew test'
                        publishTestResults testResultsPattern: 'build/test-results/test/*.xml'
                    }
                }
                
                stage('Integration Tests') {
                    steps {
                        sh './gradlew integrationTest'
                    }
                }
                
                stage('Security Scan') {
                    steps {
                        sh 'docker run --rm -v $(pwd):/app clair-scanner:latest'
                    }
                }
            }
        }
        
        stage('Quality Gates') {
            steps {
                script {
                    // SonarQube analysis
                    withSonarQubeEnv('SonarQube') {
                        sh './gradlew sonarqube'
                    }
                    
                    // Wait for quality gate
                    timeout(time: 10, unit: 'MINUTES') {
                        def qg = waitForQualityGate()
                        if (qg.status != 'OK') {
                            error "Pipeline aborted due to quality gate failure: ${qg.status}"
                        }
                    }
                }
            }
        }
        
        stage('Build Docker Image') {
            steps {
                script {
                    def image = docker.build("${DOCKER_REGISTRY}/${APP_NAME}:${BUILD_NUMBER}")
                    docker.withRegistry("https://${DOCKER_REGISTRY}", 'docker-registry-credentials') {
                        image.push()
                        image.push('latest')
                    }
                }
            }
        }
        
        stage('Deploy to Staging') {
            steps {
                script {
                    sh """
                        helm upgrade --install ${APP_NAME}-staging ./helm-chart \
                            --set image.tag=${BUILD_NUMBER} \
                            --set environment=staging \
                            --namespace staging
                    """
                }
            }
        }
        
        stage('Smoke Tests') {
            steps {
                sh 'newman run postman-collection.json --environment staging.json'
            }
        }
        
        stage('Deploy to Production') {
            when {
                branch 'main'
            }
            steps {
                script {
                    input message: 'Deploy to production?', ok: 'Deploy'
                    
                    sh """
                        helm upgrade --install ${APP_NAME} ./helm-chart \
                            --set image.tag=${BUILD_NUMBER} \
                            --set environment=production \
                            --namespace production \
                            --timeout 10m
                    """
                }
            }
        }
    }
    
    post {
        always {
            cleanWs()
        }
        
        failure {
            emailext (
                subject: "Pipeline Failed: ${env.JOB_NAME} - ${env.BUILD_NUMBER}",
                body: "Build failed. Check console output at ${env.BUILD_URL}",
                to: "${env.CHANGE_AUTHOR_EMAIL}"
            )
        }
        
        success {
            slackSend (
                channel: '#deployments',
                color: 'good',
                message: "✅ Deployment successful: ${env.JOB_NAME} - ${env.BUILD_NUMBER}"
            )
        }
    }
}
```

### GitHub Actions Workflow

```yaml
# .github/workflows/ci-cd.yml
name: CI/CD Pipeline

on:
  push:
    branches: [ main, develop ]
  pull_request:
    branches: [ main ]

env:
  REGISTRY: ghcr.io
  IMAGE_NAME: ${{ github.repository }}

jobs:
  test:
    runs-on: ubuntu-latest
    
    services:
      postgres:
        image: postgres:13
        env:
          POSTGRES_PASSWORD: postgres
        options: >-
          --health-cmd pg_isready
          --health-interval 10s
          --health-timeout 5s
          --health-retries 5
    
    steps:
    - uses: actions/checkout@v3
    
    - name: Set up JDK 17
      uses: actions/setup-java@v3
      with:
        java-version: '17'
        distribution: 'temurin'
    
    - name: Cache Gradle packages
      uses: actions/cache@v3
      with:
        path: |
          ~/.gradle/caches
          ~/.gradle/wrapper
        key: ${{ runner.os }}-gradle-${{ hashFiles('**/*.gradle*', '**/gradle-wrapper.properties') }}
    
    - name: Run tests
      run: ./gradlew test integrationTest
      env:
        DATABASE_URL: postgres://postgres:postgres@localhost:5432/testdb
    
    - name: Upload test results
      uses: actions/upload-artifact@v3
      if: always()
      with:
        name: test-results
        path: build/reports/tests/
    
    - name: SonarCloud Scan
      uses: SonarSource/sonarcloud-github-action@master
      env:
        GITHUB_TOKEN: ${{ secrets.GITHUB_TOKEN }}
        SONAR_TOKEN: ${{ secrets.SONAR_TOKEN }}

  security:
    runs-on: ubuntu-latest
    steps:
    - uses: actions/checkout@v3
    
    - name: Security vulnerability scan
      uses: aquasecurity/trivy-action@master
      with:
        scan-type: 'fs'
        scan-ref: '.'
        format: 'sarif'
        output: 'trivy-results.sarif'
    
    - name: Upload Trivy scan results
      uses: github/codeql-action/upload-sarif@v2
      with:
        sarif_file: 'trivy-results.sarif'

  build-and-push:
    needs: [test, security]
    runs-on: ubuntu-latest
    if: github.ref == 'refs/heads/main'
    
    permissions:
      contents: read
      packages: write
    
    steps:
    - uses: actions/checkout@v3
    
    - name: Log in to Container Registry
      uses: docker/login-action@v2
      with:
        registry: ${{ env.REGISTRY }}
        username: ${{ github.actor }}
        password: ${{ secrets.GITHUB_TOKEN }}
    
    - name: Extract metadata
      id: meta
      uses: docker/metadata-action@v4
      with:
        images: ${{ env.REGISTRY }}/${{ env.IMAGE_NAME }}
        tags: |
          type=ref,event=branch
          type=ref,event=pr
          type=sha,prefix={{branch}}-
          type=raw,value=latest,enable={{is_default_branch}}
    
    - name: Build and push Docker image
      uses: docker/build-push-action@v4
      with:
        context: .
        push: true
        tags: ${{ steps.meta.outputs.tags }}
        labels: ${{ steps.meta.outputs.labels }}
        cache-from: type=gha
        cache-to: type=gha,mode=max

  deploy:
    needs: build-and-push
    runs-on: ubuntu-latest
    if: github.ref == 'refs/heads/main'
    
    steps:
    - uses: actions/checkout@v3
    
    - name: Deploy to Kubernetes
      uses: azure/k8s-deploy@v1
      with:
        manifests: |
          k8s/deployment.yaml
          k8s/service.yaml
        images: |
          ${{ env.REGISTRY }}/${{ env.IMAGE_NAME }}:${{ github.sha }}
        kubeconfig: ${{ secrets.KUBE_CONFIG }}
        namespace: production
```

---

## 🐳 Containerization

### Docker Best Practices

#### Multi-stage Dockerfile

```dockerfile
# Build stage
FROM openjdk:17-jdk-slim as builder

WORKDIR /app
COPY gradle/ gradle/
COPY gradlew build.gradle settings.gradle ./
COPY src/ src/

# Cache dependencies
RUN ./gradlew dependencies --no-daemon

# Build application
RUN ./gradlew build --no-daemon -x test

# Runtime stage
FROM openjdk:17-jre-slim

# Create non-root user
RUN groupadd -r appuser && useradd -r -g appuser appuser

# Install security updates
RUN apt-get update && apt-get upgrade -y && \
    apt-get clean && rm -rf /var/lib/apt/lists/*

WORKDIR /app

# Copy built application
COPY --from=builder /app/build/libs/*.jar app.jar

# Set ownership
RUN chown -R appuser:appuser /app
USER appuser

# Health check
HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
    CMD curl -f http://localhost:8080/actuator/health || exit 1

EXPOSE 8080

ENTRYPOINT ["java", "-jar", "/app/app.jar"]
```

#### Docker Compose for Development

```yaml
# docker-compose.yml
version: '3.8'

services:
  app:
    build: .
    ports:
      - "8080:8080"
    environment:
      - SPRING_PROFILES_ACTIVE=dev
      - DATABASE_URL=jdbc:postgresql://db:5432/myapp
    depends_on:
      db:
        condition: service_healthy
    volumes:
      - ./logs:/app/logs
    networks:
      - app-network

  db:
    image: postgres:13-alpine
    environment:
      POSTGRES_DB: myapp
      POSTGRES_USER: user
      POSTGRES_PASSWORD: password
    volumes:
      - postgres_data:/var/lib/postgresql/data
      - ./init-scripts:/docker-entrypoint-initdb.d
    healthcheck:
      test: ["CMD-SHELL", "pg_isready -U user -d myapp"]
      interval: 10s
      timeout: 5s
      retries: 5
    networks:
      - app-network

  redis:
    image: redis:6-alpine
    command: redis-server --appendonly yes
    volumes:
      - redis_data:/data
    networks:
      - app-network

  nginx:
    image: nginx:alpine
    ports:
      - "80:80"
    volumes:
      - ./nginx.conf:/etc/nginx/nginx.conf
    depends_on:
      - app
    networks:
      - app-network

volumes:
  postgres_data:
  redis_data:

networks:
  app-network:
    driver: bridge
```

### Kubernetes Deployments

#### Application Deployment

```yaml
# k8s/deployment.yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: user-service
  labels:
    app: user-service
spec:
  replicas: 3
  strategy:
    type: RollingUpdate
    rollingUpdate:
      maxSurge: 1
      maxUnavailable: 1
  selector:
    matchLabels:
      app: user-service
  template:
    metadata:
      labels:
        app: user-service
    spec:
      containers:
      - name: user-service
        image: user-service:latest
        imagePullPolicy: Always
        ports:
        - containerPort: 8080
          name: http
        env:
        - name: DATABASE_URL
          valueFrom:
            secretKeyRef:
              name: db-secret
              key: url
        - name: SPRING_PROFILES_ACTIVE
          value: "production"
        resources:
          requests:
            memory: "256Mi"
            cpu: "100m"
          limits:
            memory: "512Mi"
            cpu: "500m"
        livenessProbe:
          httpGet:
            path: /actuator/health
            port: 8080
          initialDelaySeconds: 60
          periodSeconds: 30
          timeoutSeconds: 5
          failureThreshold: 3
        readinessProbe:
          httpGet:
            path: /actuator/health/readiness
            port: 8080
          initialDelaySeconds: 30
          periodSeconds: 10
          timeoutSeconds: 3
          failureThreshold: 3
        volumeMounts:
        - name: config-volume
          mountPath: /app/config
        - name: logs
          mountPath: /app/logs
      volumes:
      - name: config-volume
        configMap:
          name: user-service-config
      - name: logs
        emptyDir: {}
---
apiVersion: v1
kind: Service
metadata:
  name: user-service
spec:
  selector:
    app: user-service
  ports:
  - port: 80
    targetPort: 8080
    protocol: TCP
  type: ClusterIP
```

#### Helm Chart

```yaml
# helm-chart/values.yaml
replicaCount: 3

image:
  repository: user-service
  tag: latest
  pullPolicy: Always

service:
  type: ClusterIP
  port: 80
  targetPort: 8080

resources:
  requests:
    memory: "256Mi"
    cpu: "100m"
  limits:
    memory: "512Mi"
    cpu: "500m"

autoscaling:
  enabled: true
  minReplicas: 2
  maxReplicas: 10
  targetCPUUtilizationPercentage: 70
  targetMemoryUtilizationPercentage: 80

ingress:
  enabled: true
  className: nginx
  annotations:
    nginx.ingress.kubernetes.io/rate-limit: "100"
    cert-manager.io/cluster-issuer: "letsencrypt-prod"
  hosts:
  - host: api.mycompany.com
    paths:
    - path: /users
      pathType: Prefix
  tls:
  - secretName: api-tls
    hosts:
    - api.mycompany.com
```

---

## 🏗️ Infrastructure as Code

### Terraform Configuration

```hcl
# main.tf
terraform {
  required_version = ">= 1.0"
  
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
  
  backend "s3" {
    bucket = "mycompany-terraform-state"
    key    = "production/terraform.tfstate"
    region = "us-west-2"
  }
}

provider "aws" {
  region = var.aws_region
}

# VPC Configuration
resource "aws_vpc" "main" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_hostnames = true
  enable_dns_support   = true
  
  tags = {
    Name        = "${var.environment}-vpc"
    Environment = var.environment
  }
}

resource "aws_subnet" "private" {
  count             = length(var.availability_zones)
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.0.${count.index + 1}.0/24"
  availability_zone = var.availability_zones[count.index]
  
  tags = {
    Name = "${var.environment}-private-subnet-${count.index + 1}"
    Type = "Private"
  }
}

resource "aws_subnet" "public" {
  count                   = length(var.availability_zones)
  vpc_id                  = aws_vpc.main.id
  cidr_block              = "10.0.${count.index + 101}.0/24"
  availability_zone       = var.availability_zones[count.index]
  map_public_ip_on_launch = true
  
  tags = {
    Name = "${var.environment}-public-subnet-${count.index + 1}"
    Type = "Public"
  }
}

# EKS Cluster
resource "aws_eks_cluster" "main" {
  name     = "${var.environment}-cluster"
  role_arn = aws_iam_role.cluster.arn
  version  = "1.27"
  
  vpc_config {
    subnet_ids              = concat(aws_subnet.private[*].id, aws_subnet.public[*].id)
    endpoint_private_access = true
    endpoint_public_access  = true
    public_access_cidrs     = var.cluster_endpoint_public_access_cidrs
  }
  
  encryption_config {
    provider {
      key_arn = aws_kms_key.eks.arn
    }
    resources = ["secrets"]
  }
  
  enabled_cluster_log_types = ["api", "audit", "authenticator", "controllerManager", "scheduler"]
  
  depends_on = [
    aws_iam_role_policy_attachment.cluster_amazon_eks_cluster_policy
  ]
  
  tags = {
    Environment = var.environment
  }
}

# EKS Node Group
resource "aws_eks_node_group" "main" {
  cluster_name    = aws_eks_cluster.main.name
  node_group_name = "${var.environment}-nodes"
  node_role_arn   = aws_iam_role.node.arn
  subnet_ids      = aws_subnet.private[*].id
  instance_types  = var.node_instance_types
  
  scaling_config {
    desired_size = var.node_desired_size
    max_size     = var.node_max_size
    min_size     = var.node_min_size
  }
  
  update_config {
    max_unavailable_percentage = 25
  }
  
  # Ensure that IAM Role permissions are created before and deleted after EKS Node Group handling.
  depends_on = [
    aws_iam_role_policy_attachment.node_amazon_eks_worker_node_policy,
    aws_iam_role_policy_attachment.node_amazon_eks_cni_policy,
    aws_iam_role_policy_attachment.node_amazon_ec2_container_registry_read_only,
  ]
  
  tags = {
    Environment = var.environment
  }
}

# RDS Database
resource "aws_db_instance" "main" {
  identifier     = "${var.environment}-database"
  engine         = "postgres"
  engine_version = "13.13"
  instance_class = var.db_instance_class
  
  allocated_storage     = var.db_allocated_storage
  max_allocated_storage = var.db_max_allocated_storage
  storage_encrypted     = true
  kms_key_id           = aws_kms_key.rds.arn
  
  db_name  = var.db_name
  username = var.db_username
  password = var.db_password
  
  vpc_security_group_ids = [aws_security_group.rds.id]
  db_subnet_group_name   = aws_db_subnet_group.main.name
  
  backup_retention_period = 7
  backup_window          = "03:00-04:00"
  maintenance_window     = "sun:04:00-sun:05:00"
  
  skip_final_snapshot = false
  final_snapshot_identifier = "${var.environment}-database-final-snapshot-${formatdate("YYYY-MM-DD-hhmm", timestamp())}"
  
  performance_insights_enabled = true
  monitoring_interval         = 60
  monitoring_role_arn        = aws_iam_role.rds_monitoring.arn
  
  tags = {
    Environment = var.environment
  }
}
```

### Ansible Playbooks

```yaml
# playbooks/deploy-application.yml
---
- hosts: web_servers
  become: yes
  vars:
    app_name: user-service
    app_version: "{{ ansible_date_time.epoch }}"
    app_user: appuser
    
  tasks:
    - name: Create application user
      user:
        name: "{{ app_user }}"
        system: yes
        shell: /bin/false
        home: /opt/{{ app_name }}
        create_home: yes

    - name: Install Java
      package:
        name: openjdk-17-jre
        state: present

    - name: Download application JAR
      get_url:
        url: "{{ artifact_url }}/{{ app_name }}-{{ app_version }}.jar"
        dest: "/opt/{{ app_name }}/{{ app_name }}.jar"
        owner: "{{ app_user }}"
        group: "{{ app_user }}"
        mode: '0644'
      notify: restart application

    - name: Create application config
      template:
        src: application.yml.j2
        dest: "/opt/{{ app_name }}/application.yml"
        owner: "{{ app_user }}"
        group: "{{ app_user }}"
        mode: '0640'
      notify: restart application

    - name: Create systemd service
      template:
        src: app.service.j2
        dest: "/etc/systemd/system/{{ app_name }}.service"
        mode: '0644'
      notify:
        - reload systemd
        - restart application

    - name: Enable and start application service
      systemd:
        name: "{{ app_name }}"
        state: started
        enabled: yes
        daemon_reload: yes

    - name: Configure log rotation
      template:
        src: logrotate.j2
        dest: "/etc/logrotate.d/{{ app_name }}"
        mode: '0644'

  handlers:
    - name: reload systemd
      systemd:
        daemon_reload: yes
        
    - name: restart application
      systemd:
        name: "{{ app_name }}"
        state: restarted
```

---

## 📊 Monitoring and Observability

### Prometheus Configuration

```yaml
# prometheus.yml
global:
  scrape_interval: 15s
  evaluation_interval: 15s

rule_files:
  - "rules/*.yml"

alerting:
  alertmanagers:
    - static_configs:
        - targets:
          - alertmanager:9093

scrape_configs:
  - job_name: 'prometheus'
    static_configs:
      - targets: ['localhost:9090']

  - job_name: 'user-service'
    metrics_path: '/actuator/prometheus'
    scrape_interval: 30s
    static_configs:
      - targets: ['user-service:8080']
    relabel_configs:
      - source_labels: [__address__]
        target_label: instance
        regex: '([^:]+):.*'
        replacement: '${1}'

  - job_name: 'kubernetes-pods'
    kubernetes_sd_configs:
      - role: pod
    relabel_configs:
      - source_labels: [__meta_kubernetes_pod_annotation_prometheus_io_scrape]
        action: keep
        regex: true
      - source_labels: [__meta_kubernetes_pod_annotation_prometheus_io_path]
        action: replace
        target_label: __metrics_path__
        regex: (.+)
      - source_labels: [__address__, __meta_kubernetes_pod_annotation_prometheus_io_port]
        action: replace
        regex: ([^:]+)(?::\d+)?;(\d+)
        replacement: $1:$2
        target_label: __address__
```

### Grafana Dashboard Configuration

```json
{
  "dashboard": {
    "id": null,
    "title": "User Service Dashboard",
    "description": "Monitoring dashboard for User Service",
    "tags": ["user-service", "java", "spring-boot"],
    "timezone": "browser",
    "refresh": "30s",
    "time": {
      "from": "now-1h",
      "to": "now"
    },
    "panels": [
      {
        "id": 1,
        "title": "Request Rate",
        "type": "graph",
        "targets": [
          {
            "expr": "rate(http_requests_total{job=\"user-service\"}[5m])",
            "legendFormat": "{{method}} {{uri}}"
          }
        ],
        "yAxes": [
          {
            "label": "Requests/sec"
          }
        ]
      },
      {
        "id": 2,
        "title": "Response Time",
        "type": "graph",
        "targets": [
          {
            "expr": "histogram_quantile(0.95, rate(http_request_duration_seconds_bucket{job=\"user-service\"}[5m]))",
            "legendFormat": "95th percentile"
          },
          {
            "expr": "histogram_quantile(0.50, rate(http_request_duration_seconds_bucket{job=\"user-service\"}[5m]))",
            "legendFormat": "50th percentile"
          }
        ]
      },
      {
        "id": 3,
        "title": "Error Rate",
        "type": "singlestat",
        "targets": [
          {
            "expr": "rate(http_requests_total{job=\"user-service\",status=~\"[45].*\"}[5m]) / rate(http_requests_total{job=\"user-service\"}[5m]) * 100"
          }
        ],
        "format": "percent",
        "thresholds": "5,10"
      }
    ]
  }
}
```

### Application Logging Configuration

```yaml
# logback-spring.xml
<?xml version="1.0" encoding="UTF-8"?>
<configuration>
    <include resource="org/springframework/boot/logging/logback/defaults.xml"/>
    
    <springProfile name="!production">
        <include resource="org/springframework/boot/logging/logback/console-appender.xml"/>
        <root level="INFO">
            <appender-ref ref="CONSOLE"/>
        </root>
    </springProfile>
    
    <springProfile name="production">
        <appender name="FILE" class="ch.qos.logback.core.rolling.RollingFileAppender">
            <file>logs/application.log</file>
            <rollingPolicy class="ch.qos.logback.core.rolling.SizeAndTimeBasedRollingPolicy">
                <fileNamePattern>logs/application.%d{yyyy-MM-dd}.%i.log.gz</fileNamePattern>
                <maxFileSize>100MB</maxFileSize>
                <maxHistory>30</maxHistory>
                <totalSizeCap>5GB</totalSizeCap>
            </rollingPolicy>
            <encoder class="net.logstash.logback.encoder.LoggingEventCompositeJsonEncoder">
                <providers>
                    <timestamp/>
                    <logLevel/>
                    <loggerName/>
                    <message/>
                    <mdc/>
                    <stackTrace/>
                </providers>
            </encoder>
        </appender>
        
        <root level="INFO">
            <appender-ref ref="FILE"/>
        </root>
    </springProfile>
    
    <!-- Specific loggers -->
    <logger name="com.mycompany.userservice" level="DEBUG"/>
    <logger name="org.springframework.security" level="DEBUG"/>
    <logger name="org.hibernate.SQL" level="DEBUG"/>
</configuration>
```

---

## 🚢 Deployment Strategies

### Blue-Green Deployment

```bash
#!/bin/bash
# blue-green-deploy.sh

NAMESPACE="production"
APP_NAME="user-service"
NEW_VERSION=$1

if [ -z "$NEW_VERSION" ]; then
    echo "Usage: $0 <version>"
    exit 1
fi

# Determine current environment
CURRENT=$(kubectl get service $APP_NAME -n $NAMESPACE -o jsonpath='{.spec.selector.version}')
if [ "$CURRENT" = "blue" ]; then
    NEW_ENV="green"
else
    NEW_ENV="blue"
fi

echo "Current environment: $CURRENT"
echo "Deploying to: $NEW_ENV"

# Deploy new version
kubectl set image deployment/$APP_NAME-$NEW_ENV \
    $APP_NAME=myregistry.com/$APP_NAME:$NEW_VERSION \
    -n $NAMESPACE

# Wait for deployment to be ready
kubectl rollout status deployment/$APP_NAME-$NEW_ENV -n $NAMESPACE

# Run health checks
echo "Running health checks..."
NEW_IP=$(kubectl get service $APP_NAME-$NEW_ENV -n $NAMESPACE -o jsonpath='{.spec.clusterIP}')

for i in {1..30}; do
    if curl -f http://$NEW_IP:8080/actuator/health; then
        echo "Health check passed"
        break
    fi
    echo "Health check attempt $i failed, retrying..."
    sleep 10
done

# Switch traffic
echo "Switching traffic to $NEW_ENV environment"
kubectl patch service $APP_NAME -n $NAMESPACE -p '{"spec":{"selector":{"version":"'$NEW_ENV'"}}}'

echo "Deployment completed successfully!"
echo "To rollback, run: kubectl patch service $APP_NAME -n $NAMESPACE -p '{\"spec\":{\"selector\":{\"version\":\"$CURRENT\"}}}'"
```

### Canary Deployment with Istio

```yaml
# canary-deployment.yaml
apiVersion: argoproj.io/v1alpha1
kind: Rollout
metadata:
  name: user-service-rollout
spec:
  replicas: 10
  strategy:
    canary:
      maxSurge: "25%"
      maxUnavailable: 0
      canaryService: user-service-canary
      stableService: user-service-stable
      trafficRouting:
        istio:
          virtualService:
            name: user-service-vs
            routes:
            - primary
      steps:
      - setWeight: 10
      - pause:
          duration: 60s
      - setWeight: 20
      - pause:
          duration: 60s
      - analysis:
          templates:
          - templateName: success-rate
          args:
          - name: service-name
            value: user-service-canary
      - setWeight: 50
      - pause:
          duration: 300s
      - setWeight: 100
      - pause: {}
  selector:
    matchLabels:
      app: user-service
  template:
    metadata:
      labels:
        app: user-service
    spec:
      containers:
      - name: user-service
        image: user-service:stable
        ports:
        - containerPort: 8080

---
apiVersion: argoproj.io/v1alpha1
kind: AnalysisTemplate
metadata:
  name: success-rate
spec:
  args:
  - name: service-name
  metrics:
  - name: success-rate
    interval: 60s
    successCondition: result[0] >= 0.95
    failureLimit: 3
    provider:
      prometheus:
        address: http://prometheus:9090
        query: |
          sum(rate(http_requests_total{job="{{args.service-name}}",status!~"[45].*"}[2m])) /
          sum(rate(http_requests_total{job="{{args.service-name}}"}[2m]))
```

---

## ❓ Interview Questions

### Fundamental DevOps Questions

**Q: What is CI/CD and why is it important?**

A: **Continuous Integration/Continuous Deployment** is a software development practice where:

**Continuous Integration (CI):**
- Developers integrate code changes frequently (multiple times per day)
- Each integration triggers automated builds and tests
- Early detection of integration issues

**Continuous Deployment (CD):**
- Automated deployment to production after successful CI
- Reduces manual errors and deployment time
- Enables rapid feature delivery

**Benefits:**
- Faster time to market
- Reduced risk of deployment failures  
- Better code quality through automated testing
- Improved developer productivity

```bash
# Example CI/CD pipeline stages
1. Code Commit → 2. Build → 3. Test → 4. Security Scan → 5. Deploy Staging → 6. Integration Tests → 7. Deploy Production
```

**Q: Explain the difference between containerization and virtualization.**

A: 

| Aspect | Virtualization | Containerization |
|--------|---------------|------------------|
| **Isolation** | Hardware-level | OS-level |
| **Resource Usage** | Heavy (full OS per VM) | Lightweight (shared kernel) |
| **Startup Time** | Minutes | Seconds |
| **Portability** | Less portable | Highly portable |
| **Use Case** | Different OS requirements | Microservices, DevOps |

```dockerfile
# Container example - lightweight
FROM openjdk:17-jre-slim
COPY app.jar /app/
EXPOSE 8080
CMD ["java", "-jar", "/app/app.jar"]

# Virtual Machine would need full OS installation
```

**Q: What is Infrastructure as Code (IaC) and what are its benefits?**

A: **Infrastructure as Code** treats infrastructure configuration as software code:

**Benefits:**
- **Version Control**: Track infrastructure changes
- **Reproducibility**: Consistent environments
- **Automation**: Reduce manual configuration errors
- **Scalability**: Easy to replicate across environments
- **Documentation**: Infrastructure configuration as documentation

```hcl
# Terraform example
resource "aws_instance" "web" {
  ami           = "ami-0c55b159cbfafe1d0"
  instance_type = "t3.micro"
  
  tags = {
    Name = "WebServer"
    Environment = "production"
  }
}
```

### Advanced DevOps Questions

**Q: Design a CI/CD pipeline for a microservices architecture.**

A: Comprehensive pipeline design:

```yaml
# Multi-service pipeline
stages:
  - validate
  - build
  - test
  - security
  - deploy-staging
  - integration-tests
  - deploy-production

# Service-specific jobs
user-service:
  extends: .service-template
  variables:
    SERVICE_NAME: user-service
    SERVICE_PATH: services/user-service

order-service:
  extends: .service-template
  variables:
    SERVICE_NAME: order-service
    SERVICE_PATH: services/order-service

# Template for reusable pipeline logic
.service-template:
  script:
    - cd $SERVICE_PATH
    - docker build -t $SERVICE_NAME:$CI_COMMIT_SHA .
    - docker run --rm $SERVICE_NAME:$CI_COMMIT_SHA npm test
    - docker push $SERVICE_NAME:$CI_COMMIT_SHA
    - helm upgrade $SERVICE_NAME ./helm-chart --set image.tag=$CI_COMMIT_SHA
  only:
    changes:
      - $SERVICE_PATH/**/*
```

**Key Considerations:**
1. **Service Independence**: Each service can be deployed independently
2. **Dependency Management**: Handle inter-service dependencies
3. **Testing Strategy**: Unit, integration, and contract testing
4. **Deployment Orchestration**: Coordinate multi-service deployments
5. **Monitoring**: Track deployment health across services

**Q: How would you implement zero-downtime deployments?**

A: Multiple strategies depending on requirements:

```bash
# 1. Rolling Deployment (Kubernetes)
apiVersion: apps/v1
kind: Deployment
spec:
  strategy:
    type: RollingUpdate
    rollingUpdate:
      maxSurge: 1
      maxUnavailable: 0  # Zero downtime

# 2. Blue-Green Deployment
# Full environment switch
kubectl patch service myapp -p '{"spec":{"selector":{"version":"green"}}}'

# 3. Canary Deployment
# Gradual traffic shifting: 10% → 25% → 50% → 100%
```

**Implementation Steps:**
1. **Health Checks**: Proper liveness/readiness probes
2. **Graceful Shutdown**: Handle in-flight requests
3. **Connection Draining**: Allow existing connections to complete
4. **Database Migrations**: Backward-compatible schema changes
5. **Feature Flags**: Decouple deployment from feature activation

**Q: Design a monitoring and alerting strategy for a distributed system.**

A: Multi-layered monitoring approach:

```yaml
# 1. Infrastructure Monitoring
infrastructure_metrics:
  - cpu_utilization
  - memory_usage
  - disk_space
  - network_io

# 2. Application Metrics
application_metrics:
  - request_rate
  - response_time
  - error_rate
  - active_users

# 3. Business Metrics
business_metrics:
  - conversion_rate
  - revenue_per_hour
  - user_registrations
  - order_completion_rate

# 4. Alert Rules
alerts:
  - name: HighErrorRate
    condition: error_rate > 5%
    duration: 2m
    severity: critical
    
  - name: ResponseTimeHigh
    condition: p95_response_time > 2s
    duration: 5m
    severity: warning
```

**Monitoring Stack:**
- **Metrics**: Prometheus + Grafana
- **Logging**: ELK Stack (Elasticsearch, Logstash, Kibana)
- **Tracing**: Jaeger or Zipkin
- **Alerting**: AlertManager + PagerDuty/Slack

### System Design DevOps Questions

**Q: How would you design a deployment system that can handle thousands of services?**

A: Enterprise-scale deployment architecture:

```mermaid
graph TD
    A[Git Repository] --> B[CI/CD Orchestrator]
    B --> C[Service Discovery]
    B --> D[Deployment Engine]
    D --> E[Blue/Green Controller]
    D --> F[Canary Controller]
    E --> G[Kubernetes Clusters]
    F --> G
    G --> H[Service Mesh]
    H --> I[Monitoring & Observability]
```

**Key Components:**

1. **GitOps Workflow**
```yaml
# ArgoCD Application
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: user-service
spec:
  source:
    repoURL: https://github.com/company/k8s-manifests
    path: services/user-service
    targetRevision: HEAD
  destination:
    server: https://kubernetes.default.svc
    namespace: production
  syncPolicy:
    automated:
      prune: true
      selfHeal: true
```

2. **Multi-Cluster Management**
```bash
# Cluster federation for geographic distribution
kubectl apply -f - <<EOF
apiVersion: v1
kind: ConfigMap
metadata:
  name: cluster-config
data:
  us-west-2: "cluster-us-west-2.company.com"
  eu-west-1: "cluster-eu-west-1.company.com"
  ap-south-1: "cluster-ap-south-1.company.com"
EOF
```

3. **Deployment Strategies per Service Type**
```yaml
# Critical services: Blue-Green
critical_services:
  strategy: blue-green
  health_check_timeout: 300s
  
# Regular services: Rolling update
regular_services:
  strategy: rolling
  max_unavailable: 25%
  
# Experimental services: Canary
experimental_services:
  strategy: canary
  traffic_split: [10, 25, 50, 100]
```

**Scaling Considerations:**
- **Service Discovery**: Consul/etcd for service registration
- **Load Balancing**: Multiple layers (L4/L7)
- **Resource Management**: Namespace isolation, resource quotas
- **Security**: mTLS, RBAC, network policies
- **Observability**: Distributed tracing, centralized logging

---

## 🏷️ Tags

#devops #cicd #docker #kubernetes #terraform #ansible #monitoring #prometheus #grafana #jenkins #github-actions #infrastructure-as-code #deployment #automation #observability #sre #sde2

## 📚 Related Topics

- [[Security-Guide|DevSecOps Security Practices]]
- [[Testing-Guide|CI/CD Testing Strategies]]
- [[API-Design-Guide|API Gateway and Service Mesh]]
- [[Complete-HLD-Guide|Scalable System Architecture]]
- [[Complete-Java-Concurrency-Guide|Application Performance]]