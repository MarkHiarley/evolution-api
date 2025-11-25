#!/bin/bash

echo "🔄 Iniciando reset completo da Evolution API..."

# 1. Parar todos os containers
echo "📦 Parando containers..."
docker compose down

# 2. Remover todos os volumes
echo "🗑️  Removendo volumes antigos..."
docker volume rm evolution-api_postgres_data 2>/dev/null || true
docker volume rm evolution-api_evolution_redis 2>/dev/null || true
docker volume rm evolution-api_evolution_instances 2>/dev/null || true

# 3. Limpar volumes órfãos
echo "🧹 Limpando volumes órfãos..."
docker volume prune -f

# 4. Remover imagens antigas
echo "🖼️  Removendo imagem antiga da Evolution API..."
docker rmi evoapicloud/evolution-api:latest 2>/dev/null || true

# 5. Baixar nova imagem
echo "⬇️  Baixando versão mais recente..."
docker pull evoapicloud/evolution-api:latest

# 6. Subir os containers
echo "🚀 Subindo containers..."
docker compose up -d

# 7. Aguardar inicialização
echo "⏳ Aguardando 45 segundos para inicialização..."
sleep 45

# 8. Verificar status
echo ""
echo "✅ Verificando status dos containers:"
docker ps --filter "name=evolution"

echo ""
echo "📋 Últimos logs da API:"
docker logs evolution_api --tail 20

echo ""
echo "✅ Reset concluído!"
echo ""
echo "🔗 Acesse: http://localhost:8080"
echo "🔑 API Key: 429683C4C977415CAAFCCE10F7D57E11"
echo ""
echo "⚠️  IMPORTANTE:"
echo "   - Use um número de WhatsApp DIFERENTE ou aguarde 2-3 horas"
echo "   - Certifique-se que NÃO tem Evolution rodando no local"
