## 6. Makefile para Compilação do Host

```makefile
# Makefile para aplicação host TensorFlow Lite FPGA

# Compilador e flags
CXX = g++
CXXFLAGS = -std=c++14 -O2 -Wall -Wextra
INCLUDES = -I/usr/local/include -I/usr/local/include/opencv4
LIBS = -L/usr/local/lib -ltensorflow-lite -lopencv_core -lopencv_imgproc -lopencv_videoio -lopencv_highgui

# Arquivos fonte
SRCS = main.cpp pcie_driver.cpp camera_capture.cpp tflite_model.cpp
OBJS = $(SRCS:.cpp=.o)
TARGET = tflite_fpga_host

# Regras padrão
all: $(TARGET)

# Regra para compilar o executável
$(TARGET): $(OBJS)
	$(CXX) $(CXXFLAGS) -o $@ $^ $(LIBS)

# Regra para compilar arquivos .cpp
%.o: %.cpp
	$(CXX) $(CXXFLAGS) $(INCLUDES) -c $< -o $@

# Regra para limpar arquivos compilados
clean:
	rm -f $(OBJS) $(TARGET)

# Regra para instalar dependências (Ubuntu/Debian)
install-deps:
	sudo apt-get update
	sudo apt-get install -y build-essential
	sudo apt-get install -y libtensorflow-lite-dev
	sudo apt-get install -y libopencv-dev

# Regra para instalar dependências (CentOS/RHEL)
install-deps-centos:
	sudo yum install -y gcc-c++ make
	# Instalar TensorFlow Lite a partir do código fonte
	# Instalar OpenCV a partir do código fonte

.PHONY: all clean install-deps install-deps-centos