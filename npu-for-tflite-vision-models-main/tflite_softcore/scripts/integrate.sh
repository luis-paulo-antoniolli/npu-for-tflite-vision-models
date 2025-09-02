#!/bin/bash
# integrate.sh - Script para integrar todos os componentes do sistema

# Cores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${GREEN}=== TensorFlow Lite FPGA - Integração Completa ===${NC}"

# Verificar se estamos no diretório correto
if [ ! -d "src" ] || [ ! -d "host" ]; then
    echo -e "${RED}Erro: Diretórios src/ ou host/ não encontrados${NC}"
    echo "Por favor, execute este script na raiz do projeto"
    exit 1
fi

# 1. Sintetizar design FPGA
echo -e "${YELLOW}1. Sintetizando design FPGA...${NC}"
mkdir -p build/fpga
cp src/*.v build/fpga/
cp -r src/miaow-master build/fpga/

# Verificar se as ferramentas de síntese estão disponíveis
if command -v vivado >/dev/null 2>&1; then
    echo "Usando Xilinx Vivado para síntese"
    # Copiar script de síntese
    cp synth/tflite_softcore.tcl build/fpga/
elif command -v quartus_sh >/dev/null 2>&1; then
    echo "Usando Intel Quartus para síntese"
    # Comandos para Quartus (exemplo)
    # quartus_sh --flow compile tflite_fpga
else
    echo -e "${YELLOW}Aviso: Ferramentas de síntese não encontradas${NC}"
    echo "Os arquivos Verilog foram copiados para build/fpga/"
fi

# 2. Compilar aplicação host
echo -e "${YELLOW}2. Compilando aplicação host...${NC}"
mkdir -p build/host

# Verificar dependências
echo "Verificando dependências..."
MISSING_DEPS=0

if ! command -v g++ >/dev/null 2>&1; then
    echo -e "${RED}Erro: g++ não encontrado${NC}"
    MISSING_DEPS=1
fi

if ! pkg-config --exists tensorflow-lite 2>/dev/null; then
    echo -e "${RED}Erro: TensorFlow Lite não encontrado${NC}"
    MISSING_DEPS=1
fi

if ! pkg-config --exists opencv4 2>/dev/null; then
    echo -e "${RED}Erro: OpenCV não encontrado${NC}"
    MISSING_DEPS=1
fi

if [ $MISSING_DEPS -eq 1 ]; then
    echo -e "${YELLOW}Instalando dependências...${NC}"
    if command -v apt-get >/dev/null 2>&1; then
        sudo apt-get update
        sudo apt-get install -y build-essential libtensorflow-lite-dev libopencv-dev
    elif command -v yum >/dev/null 2>&1; then
        sudo yum install -y gcc-c++ make
        echo "Por favor, instale TensorFlow Lite e OpenCV manualmente"
    else
        echo -e "${RED}Gerenciador de pacotes não suportado. Instale as dependências manualmente${NC}"
        exit 1
    fi
fi

# Compilar aplicação host
cd host
make clean
if make; then
    echo -e "${GREEN}Aplicação host compilada com sucesso${NC}"
    cp tflite_fpga_host ../build/host/
else
    echo -e "${RED}Falha ao compilar aplicação host${NC}"
    exit 1
fi
cd ..

# 3. Criar imagem do sistema
echo -e "${YELLOW}3. Criando imagem do sistema...${NC}"
mkdir -p build/system

# Copiar arquivos necessários
cp build/host/tflite_fpga_host build/system/
cp README.md build/system/
cp -r docs build/system/

# Criar script de inicialização
cat > build/system/run.sh << 'EOF'
#!/bin/bash
echo "=== TensorFlow Lite FPGA - Execução ==="

# Verificar dispositivo PCIe
if [ ! -e /dev/pcie_fpga ]; then
    echo "Dispositivo PCIe não encontrado"
    echo "Por favor, carregue o driver apropriado"
    exit 1
fi

# Executar aplicação
./tflite_fpga_host
EOF

chmod +x build/system/run.sh

# 4. Criar pacote de instalação
echo -e "${YELLOW}4. Criando pacote de instalação...${NC}"
VERSION="1.0.0"
PACKAGE_NAME="tflite_fpga_system_${VERSION}.tar.gz"

cd build
tar -czf "../${PACKAGE_NAME}" system/
cd ..

echo -e "${GREEN}Pacote criado: ${PACKAGE_NAME}${NC}"

# 5. Resumo
echo -e "${GREEN}=== Integração Concluída ===${NC}"
echo "Artefatos gerados:"
echo "  - Design FPGA: build/fpga/"
echo "  - Aplicação host: build/host/tflite_fpga_host"
echo "  - Imagem do sistema: build/system/"
echo "  - Pacote de instalação: ${PACKAGE_NAME}"

echo ""
echo -e "${YELLOW}Próximos passos:${NC}"
echo "  1. Programe a FPGA com o design gerado"
echo "  2. Carregue o driver PCIe apropriado para seu sistema"
echo "  3. Execute o sistema com: cd build/system && ./run.sh"

echo ""
echo -e "${GREEN}Integração concluída com sucesso!${NC}"