## 5. Classe para Manipulação de Modelos TFLite (C++)

```cpp
// tflite_model.h
#ifndef TFLITE_MODEL_H
#define TFLITE_MODEL_H

#include <vector>
#include <string>
#include <tensorflow/lite/model.h>
#include <tensorflow/lite/interpreter.h>
#include <tensorflow/lite/kernels/register.h>

class TFLiteModel {
private:
    std::string model_path;
    std::unique_ptr<tfl::FlatBufferModel> model;
    std::unique_ptr<tfl::Interpreter> interpreter;
    std::vector<uint8_t> model_data;
    
public:
    TFLiteModel(const std::string& path);
    ~TFLiteModel();
    
    bool load();
    std::vector<uint8_t> getData() const;
    int getOutputSize() const;
    void processOutput(const std::vector<float>& output);
    
private:
    bool loadModelData();
};

#endif // TFLITE_MODEL_H
```

```cpp
// tflite_model.cpp
#include "tflite_model.h"
#include <fstream>
#include <iostream>

TFLiteModel::TFLiteModel(const std::string& path) : model_path(path) {
}

TFLiteModel::~TFLiteModel() {
}

bool TFLiteModel::load() {
    // Carregar modelo usando TensorFlow Lite
    model = tfl::FlatBufferModel::BuildFromFile(model_path.c_str());
    if (!model) {
        std::cerr << "Falha ao carregar modelo TFLite" << std::endl;
        return false;
    }
    
    // Construir interpretador
    tfl::ops::builtin::BuiltinOpResolver resolver;
    tfl::InterpreterBuilder builder(*model, resolver);
    builder(&interpreter);
    
    if (!interpreter) {
        std::cerr << "Falha ao construir interpretador" << std::endl;
        return false;
    }
    
    // Alocar tensores
    if (interpreter->AllocateTensors() != kTfLiteOk) {
        std::cerr << "Falha ao alocar tensores" << std::endl;
        return false;
    }
    
    // Carregar dados do modelo
    return loadModelData();
}

bool TFLiteModel::loadModelData() {
    // Ler arquivo do modelo para vetor de bytes
    std::ifstream file(model_path, std::ios::binary | std::ios::ate);
    if (!file) {
        std::cerr << "Falha ao abrir arquivo do modelo" << std::endl;
        return false;
    }
    
    std::streamsize size = file.tellg();
    file.seekg(0, std::ios::beg);
    
    model_data.resize(size);
    if (!file.read(reinterpret_cast<char*>(model_data.data()), size)) {
        std::cerr << "Falha ao ler dados do modelo" << std::endl;
        return false;
    }
    
    return true;
}

std::vector<uint8_t> TFLiteModel::getData() const {
    return model_data;
}

int TFLiteModel::getOutputSize() const {
    if (!interpreter) return 0;
    
    // Obter tamanho do tensor de saída
    int output_tensor = interpreter->outputs()[0];
    TfLiteIntArray* dims = interpreter->tensor(output_tensor)->dims;
    
    int size = 1;
    for (int i = 0; i < dims->size; i++) {
        size *= dims->data[i];
    }
    
    return size;
}

void TFLiteModel::processOutput(const std::vector<float>& output) {
    if (!interpreter) return;
    
    // Processar saída do modelo (exemplo simples)
    std::cout << "Resultado da inferência: ";
    for (size_t i = 0; i < std::min(output.size(), size_t(10)); ++i) {
        std::cout << output[i] << " ";
    }
    std::cout << std::endl;
}