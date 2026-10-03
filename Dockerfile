FROM soulter/astrbot:v4.27.5

# 切换到 root 用户安装系统依赖
USER root

# 安装 ssh 客户端并清理 apt 缓存（保持镜像轻量）
RUN apt-get update && \
    apt-get install -y --no-install-recommends openssh-client && \
    rm -rf /var/lib/apt/lists/*

# 针对 SenseVoice(Local)
# 1. 官方 CPU 专享源，安装轻量化 CPU 版 PyTorch 运行时
RUN pip install --no-cache-dir torch torchaudio --index-url https://download.pytorch.org/whl/cpu

# 2. 把编译器、分词器和 ASR 核心一次性焊死
RUN pip install --no-cache-dir funasr funasr_onnx modelscope onnxscript sentencepiece

# 如果原镜像有特定非 root 用户，可以切回去（AstrBot 默认多为 root 运行，这行通常安全）