---
title: AI - 学习TTS大模型（MOSS-TTS-Nano）
date: 2026-07-02 12:00:00 +0800
categories: [ "ai","tts"  ]
tags: [ "ai","tts" ]
author: wangfuyu
math: true 






---

## 学习TTS大模型（MOSS-TTS-Nano）

学习AI，感觉就是在烧钱，交学费。

有一些好的模型，都是需要申请个ApiKey，然后按照token进行计费使用。如果自己有设备，也能安装一些入门款的模型，那么我们的钱包不至于瘦的那么快。



### 调研

| 模型           | 核心定位                 | 语音克隆                | 多语言支持               | 硬件要求               | 部署难度 | 主要特点                                        |
| -------------- | ------------------------ | ----------------------- | ------------------------ | ---------------------- | -------- | ----------------------------------------------- |
| Confucius4-TTS | 高质量跨语种语音克隆     | 3秒音频克隆，相似度>85% | 14种，支持跨语种音色迁移 | 高 (需NVIDIA GPU)      | 中等     | 54GB资源包，情感韵律迁移能力强                  |
| MOSS-TTS-Nano  | 轻量级、CPU友好型实时TTS | 支持                    | 20种                     | 极低 (可无GPU运行)     | 简单     | 仅0.1B参数，提供ONNX版效率翻倍                  |
| QORA-TTS       | 纯Rust编写的便携式TTS    | 3-10秒音频克隆          | 10种                     | 低 (可无GPU运行)       | 极简     | 单个可执行文件，无需Python环境，内置25种音色    |
| Out Loud       | 开箱即用的桌面端TTS应用  | 不支持 (基于Kokoro-82M) | 8种                      | 极低                   | 极简     | 提供 .exe / .dmg 等安装包，带图形界面和系统托盘 |
| Soprano        | 超轻量、超高速TTS引擎    | 不支持                  | 信息缺失                 | 极低 (CPU/GPU均可)     | 简单     | 80M参数，CPU上可达20倍实时速度，内存占用<1GB    |
| VoxCPM2        | 功能全面的专业语音工作站 | 3-10秒音频克隆          | 30种                     | 高 (推荐8GB+ VRAM GPU) | 中等     | 2B参数，支持文本描述创造新音色，可LoRA微调      |

我要求的是占用空间小，跑起来顺利。能玩的起来的模型。克隆语音并且纯CPU即可的，优先用MOSS-TTS-Nano。

参考资料：

>  https://pyvideotrans.com/blog/16tts
>
> http://docs.llmvtuber.com/docs/user-guide/backend/tts/#piper-tts%E6%9C%AC%E5%9C%B0--%E8%BD%BB%E9%87%8F%E5%BF%AB%E9%80%9F



### 按照说明书操作

> https://github.com/OpenMOSS/MOSS-TTS-Nano
>
> 安装conda工具
> https://www.anaconda.com/download/success

### 安装完成

```shell
```



