#!/bin/bash

# 🚀 Script de Instalação Automática - Evolution API
# Autor: GitHub Copilot
# Data: $(date +%Y-%m-%d)

set -e  # Parar em caso de erro

# Cores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Função para logs
log() {
    echo -e "${GREEN}[$(date +'%Y-%m-%d %H:%M:%S')] $1${NC}"
}

error() {
    echo -e "${RED}[ERROR] $1${NC}"
    exit 1
}

warning() {
    echo -e "${YELLOW}[WARNING] $1${NC}"
}

info() {
    echo -e "${BLUE}[INFO] $1${NC}"
}

# Banner
echo -e "${BLUE}"
cat << "EOF"
╔═══════════════════════════════════════════════════════════════╗
║                                                               ║
║        🚀 INSTALADOR AUTOMÁTICO - EVOLUTION API 🚀           ║
║                                                               ║
║   Este script irá instalar e configurar a Evolution API      ║
║   automaticamente no seu servidor Ubuntu/Debian.            ║
║                                                               ║
╚═══════════════════════════════════════════════════════════════╝
EOF
echo -e "${NC}"

# Verificar se é root
if [[ $EUID -eq 0 ]]; then
   error "Este script não deve ser executado como root. Use um usuário normal com sudo."
fi

# Verificar sistema operacional
if ! grep -E "(Ubuntu|Debian)" /etc/os-release > /dev/null; then
    warning "Este script foi testado apenas no Ubuntu/Debian. Continuar mesmo assim? (y/N)"
    read -r response
    if [[ ! "$response" =~ ^[Yy]$ ]]; then
        exit 1
    fi
fi

log "Iniciando instalação da Evolution API..."

# 1. Atualizar sistema
log "Atualizando o sistema..."
sudo apt update && sudo apt upgrade -y

# 2. Instalar dependências básicas
log "Instalando dependências básicas..."
sudo apt install -y curl wget git unzip software-properties-common apt-transport-https ca-certificates gnupg lsb-release

# 3. Instalar Node.js 20
log "Instalando Node.js 20..."
if ! command -v node &> /dev/null; then
    curl -fsSL https://deb.nodesource.com/setup_20.x | sudo -E bash -
    sudo apt-get install -y nodejs
else
    info "Node.js já está instalado: $(node --version)"
fi

# 4. Instalar Docker
log "Instalando Docker..."
if ! command -v docker &> /dev/null; then
    curl -fsSL https://get.docker.com -o get-docker.sh
    sudo sh get-docker.sh
    sudo usermod -aG docker $USER
    rm get-docker.sh
else
    info "Docker já está instalado: $(docker --version)"
fi

# 5. Instalar Docker Compose
log "Instalando Docker Compose..."
if ! command -v docker-compose &> /dev/null; then
    sudo curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
    sudo chmod +x /usr/local/bin/docker-compose
else
    info "Docker Compose já está instalado: $(docker-compose --version)"
fi

# 6. Instalar PM2
log "Instalando PM2..."
if ! command -v pm2 &> /dev/null; then
    sudo npm install -g pm2
else
    info "PM2 já está instalado: $(pm2 --version)"
fi

# 7. Criar diretório e clonar repositório
log "Clonando repositório Evolution API..."
INSTALL_DIR="/opt/evolution-api"
if [ -d "$INSTALL_DIR" ]; then
    warning "Diretório $INSTALL_DIR já existe. Deseja sobrescrever? (y/N)"
    read -r response
    if [[ "$response" =~ ^[Yy]$ ]]; then
        sudo rm -rf $INSTALL_DIR
    else
        error "Instalação cancelada pelo usuário."
    fi
fi

sudo mkdir -p $INSTALL_DIR
sudo git clone https://github.com/EvolutionAPI/evolution-api.git $INSTALL_DIR
sudo chown -R $USER:$USER $INSTALL_DIR
cd $INSTALL_DIR

# 8. Instalar dependências NPM
log "Instalando dependências NPM..."
npm install

# 9. Configurar PostgreSQL
log "Configurando PostgreSQL..."
cd Docker/postgres
docker-compose up -d
cd ../..

info "Aguardando PostgreSQL inicializar..."
sleep 10

# Verificar se PostgreSQL está rodando
if ! docker ps | grep postgres > /dev/null; then
    error "PostgreSQL não conseguiu inicializar. Verifique os logs: docker logs postgres"
fi

# Criar banco de dados
log "Criando banco de dados..."
docker exec postgres psql -U postgres -c "CREATE DATABASE evolution_db;" 2>/dev/null || info "Banco evolution_db já existe"

# 10. Configurar Redis
log "Configurando Redis..."
cd Docker/redis
docker-compose up -d
cd ../..

info "Aguardando Redis inicializar..."
sleep 5

# 11. Configurar arquivo .env
log "Configurando arquivo .env..."
if [ ! -f .env ]; then
    cp .env.example .env 2>/dev/null || warning "Arquivo .env.example não encontrado"
fi

# Gerar API Key aleatória
API_KEY=$(openssl rand -hex 32)

# Configurar .env com valores básicos
cat > .env << EOF
# Servidor
SERVER_TYPE=http
SERVER_PORT=8080
SERVER_URL=http://localhost:8080

# CORS
CORS_ORIGIN=*
CORS_METHODS=GET,POST,PUT,DELETE
CORS_CREDENTIALS=true

# Database
DATABASE_PROVIDER=postgresql
DATABASE_CONNECTION_URI='postgresql://postgres:PASSWORD@localhost:5432/evolution_db?schema=evolution_api'
DATABASE_CONNECTION_CLIENT_NAME=evolution_exchange
DATABASE_SAVE_DATA_INSTANCE=true
DATABASE_SAVE_DATA_NEW_MESSAGE=true
DATABASE_SAVE_MESSAGE_UPDATE=true
DATABASE_SAVE_DATA_CONTACTS=true
DATABASE_SAVE_DATA_CHATS=true

# Cache Redis
CACHE_REDIS_ENABLED=true
CACHE_REDIS_URI=redis://localhost:6379/6
CACHE_REDIS_TTL=604800
CACHE_REDIS_PREFIX_KEY=evolution
CACHE_REDIS_SAVE_INSTANCES=false

# Logs
LOG_LEVEL=ERROR,WARN,INFO,LOG
LOG_COLOR=true
LOG_BAILEYS=error

# API Key
AUTHENTICATION_API_KEY=$API_KEY
AUTHENTICATION_EXPOSE_IN_FETCH_INSTANCES=true

# Instância
DEL_INSTANCE=false

# Webhook
WEBHOOK_GLOBAL_URL=''
WEBHOOK_GLOBAL_ENABLED=false

# Chatwoot
CHATWOOT_MESSAGE_READ=true
CHATWOOT_MESSAGE_DELETE=true

# Typebot
TYPEBOT_PUBLIC_URL=https://typebot.io
TYPEBOT_VIEWER_URL=https://viewer.typebot.io
EOF

# 12. Configurar banco de dados
log "Configurando banco de dados..."
npm run db:generate
npm run db:deploy

# 13. Build da aplicação
log "Compilando aplicação..."
npm run build

# 14. Configurar PM2
log "Configurando PM2..."
cat > ecosystem.config.js << EOF
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
    },
    error_file: './logs/err.log',
    out_file: './logs/out.log',
    log_file: './logs/combined.log',
    time: true
  }]
};
EOF

# Criar diretório de logs
mkdir -p logs

# 15. Configurar firewall básico
log "Configurando firewall..."
if command -v ufw &> /dev/null; then
    sudo ufw --force enable
    sudo ufw allow ssh
    sudo ufw allow 8080
    sudo ufw deny 5432
    sudo ufw deny 6379
    info "Firewall configurado com regras básicas"
else
    warning "UFW não encontrado. Configure o firewall manualmente."
fi

# 16. Iniciar aplicação
log "Iniciando aplicação com PM2..."
pm2 start ecosystem.config.js
pm2 save
pm2 startup | grep -E "sudo.*systemctl" | sh || warning "Não foi possível configurar PM2 para inicializar automaticamente"

# 17. Verificar se está funcionando
sleep 5
if pm2 list | grep "evolution-api" | grep "online" > /dev/null; then
    log "✅ Evolution API iniciada com sucesso!"
else
    error "❌ Falha ao iniciar Evolution API. Verifique os logs: pm2 logs evolution-api"
fi

# 18. Mostrar informações finais
echo -e "${GREEN}"
cat << EOF

╔═══════════════════════════════════════════════════════════════╗
║                                                               ║
║              🎉 INSTALAÇÃO CONCLUÍDA COM SUCESSO! 🎉         ║
║                                                               ║
╚═══════════════════════════════════════════════════════════════╝

📋 INFORMAÇÕES IMPORTANTES:

📍 Diretório da aplicação: $INSTALL_DIR
🔑 API Key gerada: $API_KEY
🌐 URL local: http://localhost:8080
📊 Status da aplicação: pm2 status
📋 Logs da aplicação: pm2 logs evolution-api

🔧 PRÓXIMOS PASSOS:

1. Configure um túnel (ngrok, cloudflare, etc.):
   
   # Ngrok (exemplo):
   ngrok http 8080
   
   # Depois atualize a URL no .env:
   nano $INSTALL_DIR/.env
   # Altere SERVER_URL para a URL do túnel
   
   # Reinicie a aplicação:
   pm2 restart evolution-api

2. Teste a API:
   curl http://localhost:8080

3. Criar uma instância:
   curl -X POST http://localhost:8080/instance/create \\
     -H "Content-Type: application/json" \\
     -H "apikey: $API_KEY" \\
     -d '{
       "instanceName": "teste",
       "token": "token-unico",
       "qrcode": true
     }'

📚 COMANDOS ÚTEIS:

pm2 status              # Ver status
pm2 logs evolution-api  # Ver logs
pm2 restart evolution-api # Reiniciar
pm2 stop evolution-api  # Parar
pm2 start evolution-api # Iniciar

docker ps               # Ver containers
docker logs postgres    # Logs PostgreSQL
docker logs redis       # Logs Redis

🔒 SEGURANÇA:

- Sua API Key foi gerada automaticamente
- Firewall básico configurado
- PostgreSQL e Redis não acessíveis externamente

⚠️  IMPORTANTE:

1. ANOTE SUA API KEY em local seguro!
2. Configure backup do banco de dados
3. Configure HTTPS em produção
4. Monitore logs regularmente

EOF
echo -e "${NC}"

log "Instalação finalizada! Para suporte, consulte: https://doc.evolution-api.com"
