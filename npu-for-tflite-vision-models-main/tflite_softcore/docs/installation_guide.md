# Instruções de Instalação do TFLite Softcore

## Requisitos do Sistema

### Hardware
- FPGA Xilinx Kintex UltraScale+ XCKU5P-FFVB676-2-I (ou compatível)
- Computador host com:
  - Processador de 64 bits
  - Mínimo de 8GB de RAM
  - Espaço em disco: 20GB livres
  - Interface PCIe x4 ou superior

### Software
- Sistema operacional:
  - Linux (Ubuntu 18.04 ou superior recomendado)
  - Windows 10/11 com WSL2 (opcional)
- Ferramentas de desenvolvimento:
  - Xilinx Vivado 2024.2 ou superior
  - GCC 7.0 ou superior
  - Python 3.6 ou superior
  - CMake 3.10 ou superior
- Bibliotecas:
  - TensorFlow Lite development libraries
  - OpenCV 4.0 ou superior
  - LibUSB (para programação da FPGA)

## Instalação das Ferramentas

### 1. Instalação do Xilinx Vivado

1. Baixe o Xilinx Vivado 2024.2 ou superior do site da AMD/Xilinx
2. Execute o instalador:
   ```bash
   chmod +x Xilinx_Unified_2024.2_XXXXXX.tar.gz
   tar -xzf Xilinx_Unified_2024.2_XXXXXX.tar.gz
   cd Xilinx_Unified_2024.2_XXXXXX
   sudo ./xsetup
   ```
3. Selecione "Vivado" durante a instalação
4. Instale as ferramentas de programação (Programming Cable Drivers)

### 2. Instalação das Dependências do Host

#### Ubuntu/Debian:
```bash
sudo apt-get update
sudo apt-get install -y \
    build-essential \
    gcc \
    g++ \
    cmake \
    python3 \
    python3-pip \
    libusb-1.0-0-dev \
    libgtk-3-dev \
    libavcodec-dev \
    libavformat-dev \
    libswscale-dev \
    libv4l-dev \
    libxvidcore-dev \
    libx264-dev \
    libjpeg-dev \
    libpng-dev \
    libtiff-dev \
    gfortran \
    openexr \
    libatlas-base-dev \
    python3-dev \
    python3-numpy \
    libtbb2 \
    libtbb-dev \
    libdc1394-22-dev

# Instalar TensorFlow Lite
pip3 install tensorflow-lite

# Instalar OpenCV
pip3 install opencv-python
```

#### CentOS/RHEL:
```bash
sudo yum install -y \
    gcc \
    gcc-c++ \
    make \
    cmake \
    python3 \
    python3-pip \
    libusb1-devel \
    gtk3-devel \
    ffmpeg-devel \
    libv4l-devel \
    libjpeg-turbo-devel \
    libpng-devel \
    libtiff-devel \
    openexr-devel \
    atlas-devel \
    numpy \
    tbb-devel \
    libdc1394-devel

# Instalar TensorFlow Lite
pip3 install tensorflow-lite

# Instalar OpenCV
pip3 install opencv-python
```

## Configuração do Ambiente

### 1. Configurar Variáveis de Ambiente do Vivado

Adicione as seguintes linhas ao seu `~/.bashrc` ou `~/.zshrc`:

```bash
# Xilinx Vivado
export XILINX_VIVADO=/opt/Xilinx/Vivado/2024.2
export PATH=$XILINX_VIVADO/bin:$PATH

# Adicionar bibliotecas ao LD_LIBRARY_PATH
export LD_LIBRARY_PATH=$XILINX_VIVADO/lib/lnx64.o:$LD_LIBRARY_PATH
```

Recarregue o ambiente:
```bash
source ~/.bashrc
```

### 2. Configurar Permissões USB

Para programar a FPGA via USB, adicione as regras udev:

```bash
sudo cp $XILINX_VIVADO/data/xicom/cable_drivers/lin64/install_script/installdriver/udev.rules /etc/udev/rules.d/
sudo udevadm control --reload-rules
sudo udevadm trigger
```

Adicione seu usuário ao grupo dialout:
```bash
sudo usermod -a -G dialout $USER
```

## Compilação do Projeto

### 1. Clonar o Repositório

```bash
git clone <URL_DO_REPOSITORIO>
cd tflite-softcore
```

### 2. Sintetizar o Design FPGA

```bash
cd synth
vivado -mode batch -source tflite_softcore.tcl
```

Ou execute o script batch:
```bash
cd synth
./run_synth.bat
```

### 3. Compilar a Aplicação Host

```bash
cd host
make
```

## Programação da FPGA

### 1. Conectar a FPGA

1. Conecte o cabo JTAG da FPGA ao computador
2. Conecte a FPGA à fonte de alimentação
3. Verifique a conexão:
   ```bash
   lsusb | grep -i xilinx
   ```

### 2. Programar a FPGA

```bash
# Abrir o Vivado Hardware Manager
vivado -mode batch -source program_fpga.tcl
```

Ou usando o Vivado GUI:
1. Abra o Vivado
2. Vá para "Open Hardware Manager"
3. Conecte ao hardware
4. Programe o dispositivo com o bitstream gerado

## Execução do Sistema

### 1. Carregar o Driver PCIe

```bash
# Se necessário, carregar módulos do kernel
sudo modprobe pcie_xdma
```

### 2. Executar a Aplicação Host

```bash
cd build/system
./run.sh
```

## Verificação do Funcionamento

### 1. Verificar Dispositivo PCIe

```bash
lspci | grep -i xilinx
```

### 2. Verificar Conexão com a FPGA

```bash
# Verificar se o dispositivo está disponível
ls /dev/pcie_fpga*
```

### 3. Executar Teste de Diagnóstico

```bash
cd host
./diagnostic_test
```

## Troubleshooting

### Problemas Comuns

1. **Vivado não encontrado**:
   - Verifique se as variáveis de ambiente estão configuradas corretamente
   - Confirme que o Vivado está instalado no caminho especificado

2. **Permissões USB**:
   - Certifique-se de que seu usuário está no grupo dialout
   - Verifique as regras udev

3. **Dependências ausentes**:
   - Instale todas as bibliotecas necessárias conforme a documentação

4. **Erro na programação da FPGA**:
   - Verifique as conexões do cabo JTAG
   - Confirme que a FPGA está alimentada
   - Verifique se o bitstream foi gerado corretamente

### Logs e Debugging

- Logs da aplicação host: `host/logs/`
- Relatórios de síntese: `synth/*.rpt`
- Relatórios de implementação: `synth/*.rpt`
- Arquivo de debug do Vivado: `vivado.log`

## Atualizações e Manutenção

### Atualizar o Repositório

```bash
git pull origin main
```

### Recompilar após Atualizações

```bash
# Limpar builds antigos
cd synth
rm -rf *.runs *.hw *.jou *.log

# Recompilar
vivado -mode batch -source tflite_softcore.tcl
```

## Suporte

Para suporte adicional, consulte:
- Documentação técnica em `docs/`
- Issues no repositório GitHub
- Comunidade Xilinx/AMD