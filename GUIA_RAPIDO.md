# 🚀 Guia Rápido - Evolution API

## 📋 **Instalação Rápida**

### **Método 1: Script Automático (Recomendado)**
```bash
# Baixar e executar script de instalação
wget https://raw.githubusercontent.com/EvolutionAPI/evolution-api/main/install_server.sh
chmod +x install_server.sh
./install_server.sh
```

### **Método 2: Instalação Manual**
```bash
# Pré-requisitos
sudo apt update && sudo apt upgrade -y
curl -fsSL https://deb.nodesource.com/setup_20.x | sudo -E bash -
sudo apt-get install -y nodejs docker.io docker-compose git

# Clonar e configurar
git clone https://github.com/EvolutionAPI/evolution-api.git
cd evolution-api
npm install

# Bancos de dados
cd Docker/postgres && docker-compose up -d && cd ../..
cd Docker/redis && docker-compose up -d && cd ../..
docker exec postgres psql -U postgres -c "CREATE DATABASE evolution_db;"

# Configurar e iniciar
cp .env.example .env  # Configure as variáveis
npm run db:generate
npm run db:deploy
npm run build
pm2 start dist/src/main.js --name evolution-api
```

---

## 🌐 **Configuração de Túnel**

### **ngrok (Mais Popular)**
```bash
# Instalar
curl -s https://ngrok-agent.s3.amazonaws.com/ngrok.asc | sudo tee /etc/apt/trusted.gpg.d/ngrok.asc
echo "deb https://ngrok-agent.s3.amazonaws.com buster main" | sudo tee /etc/apt/sources.list.d/ngrok.list
sudo apt update && sudo apt install ngrok

# Configurar (precisa de conta em ngrok.com)
ngrok config add-authtoken SEU_TOKEN

# Iniciar túnel
ngrok http 8080
```

### **localtunnel (Sem Cadastro)**
```bash
# Instalar
npm install -g localtunnel

# Iniciar túnel
lt --port 8080 --subdomain minha-api
# URL: https://minha-api.loca.lt
```

### **Script Automático de Túnel**
```bash
# Usar script incluído
./setup_tunnel.sh
```

---

## ⚙️ **Configurações Essenciais (.env)**

```env
# Básico
SERVER_URL=https://sua-url-do-tunnel.com
SERVER_PORT=8080
AUTHENTICATION_API_KEY=sua_chave_super_secreta

# Database
DATABASE_CONNECTION_URI='postgresql://postgres:PASSWORD@localhost:5432/evolution_db?schema=evolution_api'

# Cache (opcional)
CACHE_REDIS_ENABLED=true
CACHE_REDIS_URI=redis://localhost:6379/6

# CORS
CORS_ORIGIN=*
CORS_METHODS=GET,POST,PUT,DELETE
```

---

## 🔧 **Comandos Essenciais**

### **PM2 (Gerenciamento da Aplicação)**
```bash
pm2 start evolution-api     # Iniciar
pm2 stop evolution-api      # Parar
pm2 restart evolution-api   # Reiniciar
pm2 logs evolution-api      # Ver logs
pm2 status                  # Status de todos os processos
pm2 monit                   # Monitor em tempo real
```

### **Docker (Bancos de Dados)**
```bash
docker ps                   # Ver containers rodando
docker logs postgres        # Logs PostgreSQL
docker logs redis          # Logs Redis
docker restart postgres    # Reiniciar PostgreSQL
docker restart redis       # Reiniciar Redis
```

### **Banco de Dados**
```bash
npm run db:generate         # Gerar Prisma Client
npm run db:deploy          # Aplicar migrações
npm run db:studio          # Abrir Prisma Studio

# Backup
docker exec postgres pg_dump -U postgres evolution_db > backup.sql

# Restaurar
docker exec -i postgres psql -U postgres evolution_db < backup.sql
```

---

## 🧪 **Testando a API**

### **Verificar se está funcionando**
```bash
curl https://sua-url.com
```

### **Criar uma instância**
```bash
curl -X POST https://sua-url.com/instance/create \
  -H "Content-Type: application/json" \
  -H "apikey: SUA_API_KEY" \
  -d '{
    "instanceName": "teste",
    "token": "token-unico-123",
    "qrcode": true
  }'
```

### **Listar instâncias**
```bash
curl -X GET https://sua-url.com/instance/fetchInstances \
  -H "apikey: SUA_API_KEY"
```

### **Obter QR Code**
```bash
curl -X GET https://sua-url.com/instance/connect/teste \
  -H "apikey: SUA_API_KEY"
```

### **Enviar mensagem**
```bash
curl -X POST https://sua-url.com/message/sendText/teste \
  -H "Content-Type: application/json" \
  -H "apikey: SUA_API_KEY" \
  -d '{
    "number": "5511999999999",
    "text": "Olá! Esta é uma mensagem de teste."
  }'
```

---

## 🔒 **Segurança**

### **Firewall Básico**
```bash
sudo ufw enable
sudo ufw allow ssh
sudo ufw allow 8080
sudo ufw deny 5432    # PostgreSQL apenas local
sudo ufw deny 6379    # Redis apenas local
```

### **SSL/HTTPS** 
```bash
# Com Nginx + Certbot
sudo apt install nginx certbot python3-certbot-nginx
sudo certbot --nginx -d seu-dominio.com
```

### **API Key Segura**
```bash
# Gerar nova API key
openssl rand -hex 32

# Atualizar no .env
nano .env  # Altere AUTHENTICATION_API_KEY
pm2 restart evolution-api
```

---

## 📊 **Monitoramento**

### **Logs em Tempo Real**
```bash
# PM2
pm2 logs evolution-api --lines 100

# Docker
docker logs -f postgres
docker logs -f redis

# Sistema
tail -f /var/log/syslog | grep evolution
```

### **Uso de Recursos**
```bash
# PM2
pm2 monit

# Sistema
htop
df -h      # Espaço em disco
free -h    # Memória
```

### **Backup Automático**
```bash
# Adicionar ao crontab
crontab -e

# Backup diário às 2h
0 2 * * * docker exec postgres pg_dump -U postgres evolution_db > /backup/evolution_$(date +\%Y\%m\%d).sql
```

---

## 🆘 **Troubleshooting**

### **Aplicação não inicia**
```bash
pm2 logs evolution-api
npm run dev:server  # Para debug
```

### **Erro de conexão PostgreSQL**
```bash
docker restart postgres
docker logs postgres
```

### **QR Code não aparece**
```bash
# Verificar URL no .env
grep SERVER_URL .env

# Verificar se túnel está ativo
curl -I https://sua-url.com
```

### **Redis desconectado**
```bash
docker restart redis
# Ou desabilitar no .env:
# CACHE_REDIS_ENABLED=false
```

### **Limpar dados antigos**
```bash
# Cuidado! Isso apaga mensagens antigas
docker exec postgres psql -U postgres evolution_db -c "DELETE FROM messages WHERE created_at < NOW() - INTERVAL '30 days';"
```

---

## 🔄 **Atualizações**

### **Atualizar Evolution API**
```bash
cd /opt/evolution-api
git pull
npm install
npm run build
pm2 restart evolution-api
```

### **Atualizar dependências**
```bash
npm update
npm audit fix
```

---

## 📞 **Suporte e Links**

- 📖 [Documentação Oficial](https://doc.evolution-api.com)
- 🐛 [Reportar Issues](https://github.com/EvolutionAPI/evolution-api/issues)
- 💬 [Discord Community](https://discord.gg/evolutionapi)
- 📺 [Tutoriais YouTube](https://www.youtube.com/@evolutionapi)
- 📧 [Suporte Email](mailto:contato@evolution-api.com)

---

## ⚡ **Dicas Rápidas**

1. **Sempre faça backup** antes de atualizações
2. **Monitor logs** regularmente para detectar problemas
3. **Use HTTPS** em produção (obrigatório para WhatsApp)
4. **Mantenha API Key segura** - nunca compartilhe
5. **Configure firewall** para proteger bancos de dados
6. **Use PM2** para auto-restart em caso de crash
7. **Teste em ambiente local** antes de produção

---

**🎉 Pronto! Sua Evolution API está configurada e funcionando!**
