## 4. Classe para Captura de Câmera (C++)

```cpp
// camera_capture.h
#ifndef CAMERA_CAPTURE_H
#define CAMERA_CAPTURE_H

#include <vector>
#include <opencv2/opencv.hpp>

class CameraCapture {
private:
    cv::VideoCapture cap;
    int width, height;
    
public:
    CameraCapture(int camera_id = 0, int width = 640, int height = 480);
    ~CameraCapture();
    
    bool init();
    std::vector<float> captureFrame();
    void release();
    
private:
    std::vector<float> preprocessImage(const cv::Mat& image);
};

#endif // CAMERA_CAPTURE_H
```

```cpp
// camera_capture.cpp
#include "camera_capture.h"
#include <iostream>

CameraCapture::CameraCapture(int camera_id, int w, int h) 
    : cap(camera_id), width(w), height(h) {
}

CameraCapture::~CameraCapture() {
    release();
}

bool CameraCapture::init() {
    if (!cap.isOpened()) {
        std::cerr << "Não foi possível abrir a câmera" << std::endl;
        return false;
    }
    
    // Configurar propriedades da câmera
    cap.set(cv::CAP_PROP_FRAME_WIDTH, width);
    cap.set(cv::CAP_PROP_FRAME_HEIGHT, height);
    
    return true;
}

std::vector<float> CameraCapture::captureFrame() {
    cv::Mat frame;
    cap >> frame;
    
    if (frame.empty()) {
        std::cerr << "Falha ao capturar frame" << std::endl;
        return std::vector<float>();
    }
    
    return preprocessImage(frame);
}

std::vector<float> CameraCapture::preprocessImage(const cv::Mat& image) {
    // Redimensionar imagem se necessário
    cv::Mat resized;
    if (image.cols != width || image.rows != height) {
        cv::resize(image, resized, cv::Size(width, height));
    } else {
        resized = image;
    }
    
    // Converter para float e normalizar
    cv::Mat float_image;
    resized.convertTo(float_image, CV_32F, 1.0/255.0);
    
    // Converter para vetor
    std::vector<float> result(float_image.total() * float_image.channels());
    std::memcpy(result.data(), float_image.data, result.size() * sizeof(float));
    
    return result;
}

void CameraCapture::release() {
    if (cap.isOpened()) {
        cap.release();
    }
}