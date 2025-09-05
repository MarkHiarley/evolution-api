# 🚀 Tutorial de Instalação - Evolution API

## 📋 **Pré-requisitos**

### **No seu servidor:**
- Ubuntu/Debian (recomendado) ou CentOS/RHEL
- Node.js 18+ (recomendado: 20+)
- Docker e Docker Compose
- Git
- Pelo menos 2GB RAM e 20GB de espaço

---

## 🛠️ **1. Preparação do Servidor**

### **Atualizar o sistema:**
```bash
sudo apt update && sudo apt upgrade -y
```

### **Instalar Node.js (via NodeSource):**
```bash
curl -fsSL https://deb.nodesource.com/setup_20.x | sudo -E bash -
sudo apt-get install -y nodejs
```

### **Instalar Docker:**
```bash
curl -fsSL https://get.docker.com -o get-docker.sh
sudo sh get-docker.sh
sudo usermod -aG docker $USER
```

### **Instalar Docker Compose:**
```bash
sudo curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
sudo chmod +x /usr/local/bin/docker-compose
```

### **Reiniciar para aplicar permissões do Docker:**
```bash
sudo reboot
```

---

## 📥 **2. Download e Configuração**

### **Clonar o repositório:**
```bash
cd /opt
sudo git clone https://github.com/EvolutionAPI/evolution-api.git
sudo chown -R $USER:$USER evolution-api
cd evolution-api
```

### **Instalar dependências:**
```bash
npm install
```

---

## 🗄️ **3. Configuração do Banco de Dados**

### **Iniciar PostgreSQL:**
```bash
cd Docker/postgres
docker-compose up -d
cd ../..
```

### **Aguardar alguns segundos e verificar se está rodando:**
```bash
docker ps | grep postgres
```

### **Criar o banco de dados:**
```bash
docker exec postgres psql -U postgres -c "CREATE DATABASE evolution_db;"
```

---

## ⚙️ **4. Configuração das Variáveis (.env)**

### **Copiar o arquivo de exemplo:**
```bash
cp .env.example .env
```

### **Principais configurações para servidor:**

```env
# Servidor
SERVER_TYPE=http
SERVER_PORT=8080
SERVER_URL=http://localhost:8080  # Você vai alterar depois com a URL do túnel

# CORS (para permitir acesso externo)
CORS_ORIGIN=*
CORS_METHODS=GET,POST,PUT,DELETE
CORS_CREDENTIALS=true

# Database (PostgreSQL)
DATABASE_PROVIDER=postgresql
DATABASE_CONNECTION_URI='postgresql://postgres:PASSWORD@localhost:5432/evolution_db?schema=evolution_api'
DATABASE_CONNECTION_CLIENT_NAME=evolution_exchange

# Logs
LOG_LEVEL=ERROR,WARN,INFO,LOG
LOG_COLOR=true
LOG_BAILEYS=error

# Cache Redis (recomendado para produção)
CACHE_REDIS_ENABLED=true
CACHE_REDIS_URI=redis://localhost:6379/6
CACHE_REDIS_TTL=604800
CACHE_REDIS_PREFIX_KEY=evolution
CACHE_REDIS_SAVE_INSTANCES=false

# Webhook (configure se necessário)
WEBHOOK_GLOBAL_URL=''
WEBHOOK_GLOBAL_ENABLED=false
WEBHOOK_GLOBAL_WEBHOOK_BY_EVENTS=false

# Chatwoot (se for usar)
CHATWOOT_MESSAGE_READ=true
CHATWOOT_MESSAGE_DELETE=true
CHATWOOT_IMPORT_DATABASE_CONNECTION_URI=''
CHATWOOT_IMPORT_PLACEHOLDER_MEDIA_MESSAGE=true

# Typebot (se for usar)
TYPEBOT_PUBLIC_URL=https://typebot.io
TYPEBOT_VIEWER_URL=https://viewer.typebot.io

# API Key (defina uma chave segura)
AUTHENTICATION_API_KEY=sua_chave_super_secreta_aqui
AUTHENTICATION_EXPOSE_IN_FETCH_INSTANCES=true
```

---

## 🔴 **5. Configuração do Redis**

### **Iniciar Redis:**
```bash
cd Docker/redis
docker-compose up -d
cd ../..
```

### **Verificar se está rodando:**
```bash
docker ps | grep redis
```

---

## 💾 **6. Configuração do Banco**

### **Gerar o Prisma Client:**
```bash
npm run db:generate
```

### **Aplicar as migrações:**
```bash
npm run db:deploy
```

---

## 🚀 **7. Iniciar a Aplicação**

### **Para desenvolvimento/teste:**
```bash
npm run dev:server
```

### **Para produção (com PM2):**

#### **Instalar PM2:**
```bash
sudo npm install -g pm2
```

#### **Criar arquivo ecosystem.config.js:**
```javascript
module.exports = {
  apps: [{
    name: 'evolution-api',
    script: './dist/src/main.js',
    instances: 1,
    autorestart: true,
    watch: false,
    max_memory_restart: '1G',
    env: {
      NODE_ENV: 'production'
    }
  }]
};
```

#### **Build da aplicação:**
```bash
npm run build
```

#### **Iniciar com PM2:**
```bash
pm2 start ecosystem.config.js
pm2 save
pm2 startup
```

---

## 🌐 **8. Configuração do Túnel**

### **Opção 1: Ngrok (mais fácil)**
```bash
# Instalar ngrok
curl -s https://ngrok-agent.s3.amazonaws.com/ngrok.asc | sudo tee /etc/apt/trusted.gpg.d/ngrok.asc
echo "deb https://ngrok-agent.s3.amazonaws.com buster main" | sudo tee /etc/apt/sources.list.d/ngrok.list
sudo apt update && sudo apt install ngrok

# Autenticar (faça conta gratuita em ngrok.com)
ngrok config add-authtoken seu_token_aqui

# Criar túnel
ngrok http 8080
```

### **Opção 2: Cloudflare Tunnel (gratuito e permanente)**
```bash
# Instalar cloudflared
wget -q https://github.com/cloudflare/cloudflared/releases/latest/download/cloudflared-linux-amd64.deb
sudo dpkg -i cloudflared-linux-amd64.deb

# Autenticar
cloudflared tunnel login

# Criar túnel
cloudflared tunnel create evolution-api

# Configurar túnel
nano ~/.cloudflared/config.yml
```

**Conteúdo do config.yml:**
```yaml
tunnel: seu-tunnel-id-aqui
credentials-file: /home/usuario/.cloudflared/seu-tunnel-id-aqui.json

ingress:
  - hostname: evolution.seu-dominio.com
    service: http://localhost:8080
  - service: http_status:404
```

**Iniciar túnel:**
```bash
cloudflared tunnel run evolution-api
```

---

## 🔧 **9. Atualizar URL no .env**

### **Depois de configurar o túnel, edite o .env:**
```env
# Substitua pela URL do seu túnel
SERVER_URL=https://sua-url-do-tunnel.ngrok-free.app
# ou
SERVER_URL=https://evolution.seu-dominio.com
```

### **Reiniciar a aplicação:**
```bash
# Se usando npm
npm run dev:server

# Se usando PM2
pm2 restart evolution-api
```

---

## 🧪 **10. Testar a Instalação**

### **Verificar se está funcionando:**
```bash
curl http://localhost:8080
# ou
curl https://sua-url-do-tunnel.com
```

### **Criar uma instância de teste:**
```bash
curl -X POST https://sua-url-do-tunnel.com/instance/create \
  -H "Content-Type: application/json" \
  -H "apikey: sua_chave_super_secreta_aqui" \
  -d '{
    "instanceName": "teste",
    "token": "token-unico-aqui",
    "qrcode": true
  }'
```

---

## 🔒 **11. Segurança (IMPORTANTE)**

### **Firewall básico:**
```bash
sudo ufw enable
sudo ufw allow ssh
sudo ufw allow 8080
# Bloquear acesso direto ao PostgreSQL e Redis de fora
sudo ufw deny 5432
sudo ufw deny 6379
```

### **Nginx como proxy reverso (opcional mas recomendado):**
```bash
sudo apt install nginx

# Configurar um virtual host
sudo nano /etc/nginx/sites-available/evolution-api
```

**Conteúdo do nginx:**
```nginx
server {
    listen 80;
    server_name seu-dominio.com;

    location / {
        proxy_pass http://localhost:8080;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        proxy_cache_bypass $http_upgrade;
    }
}
```

```bash
sudo ln -s /etc/nginx/sites-available/evolution-api /etc/nginx/sites-enabled/
sudo nginx -t
sudo systemctl restart nginx
```

---

## 📊 **12. Monitoramento**

### **Ver logs em tempo real:**
```bash
# PM2
pm2 logs evolution-api

# Docker containers
docker logs postgres -f
docker logs redis -f
```

### **Status dos serviços:**
```bash
pm2 status
docker ps
```

---

## 🛠️ **13. Comandos Úteis para Manutenção**

### **Backup do banco:**
```bash
docker exec postgres pg_dump -U postgres evolution_db > backup_$(date +%Y%m%d).sql
```

### **Restaurar backup:**
```bash
docker exec -i postgres psql -U postgres evolution_db < backup_20241205.sql
```

### **Atualizar a aplicação:**
```bash
git pull
npm install
npm run build
pm2 restart evolution-api
```

### **Limpar dados antigos:**
```bash
# Limpar mensagens antigas (cuidado!)
docker exec postgres psql -U postgres evolution_db -c "DELETE FROM messages WHERE created_at < NOW() - INTERVAL '30 days';"
```

---

## ⚠️ **Troubleshooting**

### **Problemas comuns:**

1. **Erro de conexão PostgreSQL:**
   ```bash
   docker restart postgres
   ```

2. **Redis não conecta:**
   ```bash
   docker restart redis
   ```

3. **Aplicação não inicia:**
   ```bash
   pm2 logs evolution-api
   ```

4. **QR Code não aparece:**
   - Verificar se a URL está correta no .env
   - Verificar se o túnel está funcionando

---

## 📞 **Suporte**

- [Documentação Oficial](https://doc.evolution-api.com)
- [GitHub Issues](https://github.com/EvolutionAPI/evolution-api/issues)
- [Discord Community](https://discord.gg/evolutionapi)

---

## ✅ **Checklist Final**

- [ ] Servidor atualizado
- [ ] Node.js 20+ instalado
- [ ] Docker e Docker Compose funcionando
- [ ] PostgreSQL rodando
- [ ] Redis rodando (opcional)
- [ ] Aplicação buildada
- [ ] PM2 configurado
- [ ] Túnel configurado
- [ ] URL atualizada no .env
- [ ] API Key definida
- [ ] Firewall configurado
- [ ] Teste de conexão OK

**🎉 Parabéns! Sua Evolution API está pronta para produção!**
