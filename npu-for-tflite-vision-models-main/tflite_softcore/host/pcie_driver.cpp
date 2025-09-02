## 2. Driver PCIe para Host (C++)

```cpp
// pcie_driver.h
#ifndef PCIE_DRIVER_H
#define PCIE_DRIVER_H

#include <cstdint>
#include <vector>
#include <string>

class PCIEDriver {
private:
    int fd; // File descriptor para o dispositivo PCIe
    uintptr_t base_addr; // Endereço base do mmap
    
public:
    PCIEDriver(const std::string& device_path);
    ~PCIEDriver();
    
    // Comandos disponíveis
    enum Command {
        LOAD_MODEL = 0x01,
        LOAD_INPUT = 0x02,
        RUN_INFERENCE = 0x03,
        GET_RESULT = 0x04
    };
    
    // Métodos para comunicação com a FPGA
    bool loadModel(const std::vector<uint8_t>& model_data);
    bool loadInput(const std::vector<float>& input_data);
    bool runInference();
    std::vector<float> getResult(int output_size);
    
    // Métodos auxiliares
    bool sendCommand(uint8_t cmd, uint32_t addr, uint32_t data, uint32_t length);
    bool sendData(const std::vector<uint32_t>& data);
    std::vector<uint32_t> receiveData(int length);
    
private:
    bool openDevice(const std::string& device_path);
    void closeDevice();
    bool mmapDevice();
    void munmapDevice();
};

#endif // PCIE_DRIVER_H
```

```cpp
// pcie_driver.cpp
#include "pcie_driver.h"
#include <fcntl.h>
#include <unistd.h>
#include <sys/mman.h>
#include <sys/ioctl.h>
#include <cstring>
#include <iostream>

PCIEDriver::PCIEDriver(const std::string& device_path) : fd(-1), base_addr(0) {
    if (!openDevice(device_path)) {
        std::cerr << "Falha ao abrir dispositivo PCIe" << std::endl;
    }
    
    if (!mmapDevice()) {
        std::cerr << "Falha no mapeamento de memória" << std::endl;
    }
}

PCIEDriver::~PCIEDriver() {
    munmapDevice();
    closeDevice();
}

bool PCIEDriver::openDevice(const std::string& device_path) {
    fd = open(device_path.c_str(), O_RDWR);
    return fd >= 0;
}

void PCIEDriver::closeDevice() {
    if (fd >= 0) {
        close(fd);
        fd = -1;
    }
}

bool PCIEDriver::mmapDevice() {
    // Mapear a memória do dispositivo PCIe
    base_addr = (uintptr_t)mmap(nullptr, 4096, PROT_READ | PROT_WRITE, MAP_SHARED, fd, 0);
    return base_addr != (uintptr_t)MAP_FAILED;
}

void PCIEDriver::munmapDevice() {
    if (base_addr) {
        munmap((void*)base_addr, 4096);
        base_addr = 0;
    }
}

bool PCIEDriver::sendCommand(uint8_t cmd, uint32_t addr, uint32_t data, uint32_t length) {
    // Enviar comando para a FPGA
    volatile uint32_t* reg = (volatile uint32_t*)base_addr;
    
    reg[0] = cmd;
    reg[1] = addr;
    reg[2] = data;
    reg[3] = length;
    
    return true;
}

bool PCIEDriver::sendData(const std::vector<uint32_t>& data) {
    // Enviar dados para a FPGA
    volatile uint32_t* reg = (volatile uint32_t*)base_addr;
    
    for (size_t i = 0; i < data.size(); ++i) {
        reg[4 + i] = data[i]; // Assumindo que os dados começam no offset 16 bytes
    }
    
    return true;
}

std::vector<uint32_t> PCIEDriver::receiveData(int length) {
    // Receber dados da FPGA
    std::vector<uint32_t> data(length);
    volatile uint32_t* reg = (volatile uint32_t*)base_addr;
    
    for (int i = 0; i < length; ++i) {
        data[i] = reg[4 + i]; // Assumindo que os dados começam no offset 16 bytes
    }
    
    return data;
}

bool PCIEDriver::loadModel(const std::vector<uint8_t>& model_data) {
    // Converter bytes para words de 32 bits
    std::vector<uint32_t> words((model_data.size() + 3) / 4, 0);
    
    for (size_t i = 0; i < model_data.size(); ++i) {
        words[i / 4] |= (static_cast<uint32_t>(model_data[i]) << (8 * (i % 4)));
    }
    
    // Enviar comando para carregar modelo
    if (!sendCommand(LOAD_MODEL, 0x00000000, 0, words.size())) {
        return false;
    }
    
    // Enviar dados do modelo
    return sendData(words);
}

bool PCIEDriver::loadInput(const std::vector<float>& input_data) {
    // Converter floats para words de 32 bits
    const uint32_t* words = reinterpret_cast<const uint32_t*>(input_data.data());
    std::vector<uint32_t> data(words, words + input_data.size());
    
    // Enviar comando para carregar entrada
    if (!sendCommand(LOAD_INPUT, 0x00100000, 0, data.size())) {
        return false;
    }
    
    // Enviar dados de entrada
    return sendData(data);
}

bool PCIEDriver::runInference() {
    // Enviar comando para executar inferência
    return sendCommand(RUN_INFERENCE, 0, 0, 0);
}

std::vector<float> PCIEDriver::getResult(int output_size) {
    // Enviar comando para obter resultado
    sendCommand(GET_RESULT, 0, 0, output_size);
    
    // Receber dados do resultado
    std::vector<uint32_t> data = receiveData(output_size);
    
    // Converter words de 32 bits para floats
    std::vector<float> result(data.size());
    std::memcpy(result.data(), data.data(), data.size() * sizeof(uint32_t));
    
    return result;
}
```