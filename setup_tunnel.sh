#!/bin/bash

# 🌐 Script para configurar túnel com Evolution API
# Suporta: ngrok, cloudflare tunnel, localtunnel

set -e

# Cores
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
RED='\033[0;31m'
NC='\033[0m'

log() {
    echo -e "${GREEN}[$(date +'%H:%M:%S')] $1${NC}"
}

warning() {
    echo -e "${YELLOW}[WARNING] $1${NC}"
}

info() {
    echo -e "${BLUE}[INFO] $1${NC}"
}

error() {
    echo -e "${RED}[ERROR] $1${NC}"
    exit 1
}

# Banner
echo -e "${BLUE}"
cat << "EOF"
╔═══════════════════════════════════════════════════════════════╗
║                                                               ║
║           🌐 CONFIGURADOR DE TÚNEL - EVOLUTION API           ║
║                                                               ║
╚═══════════════════════════════════════════════════════════════╝
EOF
echo -e "${NC}"

# Verificar se a Evolution API está rodando
if ! curl -s http://localhost:8080 > /dev/null; then
    error "Evolution API não está rodando em localhost:8080. Inicie-a primeiro!"
fi

# Menu de opções
echo "Escolha o tipo de túnel:"
echo "1) ngrok (mais fácil, precisa de conta)"
echo "2) localtunnel (gratuito, sem cadastro)"
echo "3) cloudflare tunnel (gratuito, permanente)"
echo "4) Apenas mostrar comandos manuais"
echo ""
read -p "Digite sua opção (1-4): " option

case $option in
    1)
        log "Configurando ngrok..."
        
        # Verificar se ngrok está instalado
        if ! command -v ngrok &> /dev/null; then
            log "Instalando ngrok..."
            
            # Download e instalação
            if [[ "$OSTYPE" == "linux-gnu"* ]]; then
                wget -q https://bin.equinox.io/c/bNyj1mQVY4c/ngrok-v3-stable-linux-amd64.tgz
                tar -xzf ngrok-v3-stable-linux-amd64.tgz
                sudo mv ngrok /usr/local/bin/
                rm ngrok-v3-stable-linux-amd64.tgz
            elif [[ "$OSTYPE" == "darwin"* ]]; then
                brew install ngrok/ngrok/ngrok 2>/dev/null || {
                    warning "Homebrew não encontrado. Baixe ngrok manualmente de: https://ngrok.com/download"
                    exit 1
                }
            else
                error "SO não suportado para instalação automática. Baixe manualmente: https://ngrok.com/download"
            fi
        fi
        
        # Verificar se está autenticado
        if ! ngrok config check &> /dev/null; then
            warning "ngrok não está configurado. Siga estes passos:"
            echo ""
            echo "1. Vá para: https://dashboard.ngrok.com/signup"
            echo "2. Crie uma conta gratuita"
            echo "3. Vá para: https://dashboard.ngrok.com/get-started/your-authtoken"
            echo "4. Copie seu authtoken"
            echo ""
            read -p "Cole seu authtoken do ngrok aqui: " authtoken
            
            if [ -n "$authtoken" ]; then
                ngrok config add-authtoken "$authtoken"
                log "ngrok configurado com sucesso!"
            else
                error "Authtoken não fornecido"
            fi
        fi
        
        log "Iniciando túnel ngrok..."
        echo ""
        info "Abrindo túnel para localhost:8080..."
        info "Pressione Ctrl+C para parar"
        echo ""
        
        # Iniciar ngrok e capturar URL
        ngrok http 8080 &
        NGROK_PID=$!
        
        # Aguardar ngrok inicializar
        sleep 5
        
        # Obter URL do túnel
        TUNNEL_URL=$(curl -s http://localhost:4040/api/tunnels | grep -o 'https://[^"]*\.ngrok-free\.app' | head -1)
        
        if [ -n "$TUNNEL_URL" ]; then
            log "✅ Túnel criado com sucesso!"
            echo ""
            echo "🌐 URL do túnel: $TUNNEL_URL"
            echo ""
            
            # Atualizar .env automaticamente
            if [ -f ".env" ]; then
                warning "Deseja atualizar o .env automaticamente com a nova URL? (y/N)"
                read -r response
                if [[ "$response" =~ ^[Yy]$ ]]; then
                    sed -i "s|SERVER_URL=.*|SERVER_URL=$TUNNEL_URL|" .env
                    log ".env atualizado!"
                    
                    # Reiniciar PM2 se estiver rodando
                    if pm2 list 2>/dev/null | grep "evolution-api" > /dev/null; then
                        warning "Reiniciando Evolution API..."
                        pm2 restart evolution-api
                        log "Evolution API reiniciada!"
                    fi
                fi
            fi
            
            echo ""
            info "Teste sua API em: $TUNNEL_URL"
            info "Dashboard do ngrok: http://localhost:4040"
            echo ""
            
            # Manter rodando
            wait $NGROK_PID
        else
            error "Não foi possível obter URL do túnel"
        fi
        ;;
        
    2)
        log "Configurando localtunnel..."
        
        # Instalar localtunnel
        if ! command -v lt &> /dev/null; then
            log "Instalando localtunnel..."
            sudo npm install -g localtunnel
        fi
        
        log "Iniciando túnel localtunnel..."
        echo ""
        info "Abrindo túnel para localhost:8080..."
        info "Pressione Ctrl+C para parar"
        echo ""
        
        # Gerar subdomain aleatório
        SUBDOMAIN="evolution-$(date +%s)"
        
        lt --port 8080 --subdomain "$SUBDOMAIN" &
        LT_PID=$!
        
        sleep 3
        TUNNEL_URL="https://$SUBDOMAIN.loca.lt"
        
        log "✅ Túnel criado com sucesso!"
        echo ""
        echo "🌐 URL do túnel: $TUNNEL_URL"
        echo ""
        
        # Atualizar .env
        if [ -f ".env" ]; then
            warning "Deseja atualizar o .env automaticamente? (y/N)"
            read -r response
            if [[ "$response" =~ ^[Yy]$ ]]; then
                sed -i "s|SERVER_URL=.*|SERVER_URL=$TUNNEL_URL|" .env
                log ".env atualizado!"
                
                if pm2 list 2>/dev/null | grep "evolution-api" > /dev/null; then
                    pm2 restart evolution-api
                    log "Evolution API reiniciada!"
                fi
            fi
        fi
        
        echo ""
        info "Teste sua API em: $TUNNEL_URL"
        warning "ATENÇÃO: Na primeira vez, você precisará clicar em 'Click to Continue' no navegador"
        echo ""
        
        wait $LT_PID
        ;;
        
    3)
        log "Configuração do Cloudflare Tunnel..."
        echo ""
        info "Para configurar Cloudflare Tunnel, siga estes passos:"
        echo ""
        echo "1. Instale cloudflared:"
        echo "   wget -q https://github.com/cloudflare/cloudflared/releases/latest/download/cloudflared-linux-amd64.deb"
        echo "   sudo dpkg -i cloudflared-linux-amd64.deb"
        echo ""
        echo "2. Autentique:"
        echo "   cloudflared tunnel login"
        echo ""
        echo "3. Crie um túnel:"
        echo "   cloudflared tunnel create evolution-api"
        echo ""
        echo "4. Configure DNS no seu domínio Cloudflare:"
        echo "   cloudflared tunnel route dns evolution-api api.seudominio.com"
        echo ""
        echo "5. Crie arquivo de configuração:"
        echo "   nano ~/.cloudflared/config.yml"
        echo ""
        echo "   Conteúdo:"
        echo "   tunnel: SEU-TUNNEL-ID"
        echo "   credentials-file: ~/.cloudflared/SEU-TUNNEL-ID.json"
        echo "   ingress:"
        echo "     - hostname: api.seudominio.com"
        echo "       service: http://localhost:8080"
        echo "     - service: http_status:404"
        echo ""
        echo "6. Inicie o túnel:"
        echo "   cloudflared tunnel run evolution-api"
        echo ""
        ;;
        
    4)
        log "Comandos manuais para diferentes túneis:"
        echo ""
        echo "🔥 NGROK:"
        echo "   # Instalar e configurar"
        echo "   curl -s https://ngrok-agent.s3.amazonaws.com/ngrok.asc | sudo tee /etc/apt/trusted.gpg.d/ngrok.asc"
        echo "   echo 'deb https://ngrok-agent.s3.amazonaws.com buster main' | sudo tee /etc/apt/sources.list.d/ngrok.list"
        echo "   sudo apt update && sudo apt install ngrok"
        echo "   ngrok config add-authtoken SEU_TOKEN"
        echo "   ngrok http 8080"
        echo ""
        echo "🌍 LOCALTUNNEL:"
        echo "   npm install -g localtunnel"
        echo "   lt --port 8080 --subdomain minha-api"
        echo ""
        echo "☁️ CLOUDFLARE TUNNEL:"
        echo "   wget https://github.com/cloudflare/cloudflared/releases/latest/download/cloudflared-linux-amd64.deb"
        echo "   sudo dpkg -i cloudflared-linux-amd64.deb"
        echo "   cloudflared tunnel login"
        echo "   cloudflared tunnel create meu-tunnel"
        echo "   cloudflared tunnel route dns meu-tunnel api.meudominio.com"
        echo "   cloudflared tunnel run meu-tunnel"
        echo ""
        echo "🔗 SERVEO (sem instalação):"
        echo "   ssh -R 80:localhost:8080 serveo.net"
        echo ""
        echo "🚀 BORE (Rust):"
        echo "   cargo install bore-cli"
        echo "   bore local 8080 --to bore.pub"
        echo ""
        ;;
        
    *)
        error "Opção inválida"
        ;;
esac

echo ""
log "Configuração de túnel finalizada!"
