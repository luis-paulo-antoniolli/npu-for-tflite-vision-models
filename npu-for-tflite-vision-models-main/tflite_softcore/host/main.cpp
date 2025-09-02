## 3. Aplicação Host Principal (C++)

```cpp
// main.cpp
#include "pcie_driver.h"
#include "camera_capture.h"
#include "tflite_model.h"
#include <iostream>
#include <vector>
#include <chrono>

int main() {
    // Inicializar driver PCIe
    PCIEDriver driver("/dev/pcie_fpga");
    
    // Carregar modelo TFLite
    TFLiteModel model("model.tflite");
    if (!model.load()) {
        std::cerr << "Falha ao carregar modelo" << std::endl;
        return -1;
    }
    
    // Enviar modelo para FPGA
    std::vector<uint8_t> model_data = model.getData();
    if (!driver.loadModel(model_data)) {
        std::cerr << "Falha ao enviar modelo para FPGA" << std::endl;
        return -1;
    }
    
    std::cout << "Modelo carregado com sucesso na FPGA" << std::endl;
    
    // Inicializar captura de câmera
    CameraCapture camera;
    if (!camera.init()) {
        std::cerr << "Falha ao inicializar câmera" << std::endl;
        return -1;
    }
    
    std::cout << "Captura de câmera inicializada" << std::endl;
    
    // Loop principal de inferência
    while (true) {
        // Capturar frame da câmera
        std::vector<float> frame = camera.captureFrame();
        if (frame.empty()) {
            std::cerr << "Falha ao capturar frame" << std::endl;
            continue;
        }
        
        auto start = std::chrono::high_resolution_clock::now();
        
        // Enviar dados de entrada para FPGA
        if (!driver.loadInput(frame)) {
            std::cerr << "Falha ao enviar dados de entrada" << std::endl;
            continue;
        }
        
        // Executar inferência na FPGA
        if (!driver.runInference()) {
            std::cerr << "Falha ao executar inferência" << std::endl;
            continue;
        }
        
        // Obter resultado da FPGA
        std::vector<float> result = driver.getResult(model.getOutputSize());
        
        auto end = std::chrono::high_resolution_clock::now();
        auto duration = std::chrono::duration_cast<std::chrono::milliseconds>(end - start);
        
        // Processar resultado
        std::cout << "Inferência concluída em " << duration.count() << " ms" << std::endl;
        model.processOutput(result);
        
        // Pequeno atraso para não sobrecarregar o sistema
        std::this_thread::sleep_for(std::chrono::milliseconds(100));
    }
    
    return 0;
}