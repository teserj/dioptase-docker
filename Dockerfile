FROM ubuntu:latest

# Avoid interactive prompts during installation
ENV DEBIAN_FRONTEND=noninteractive
ENV TERM=xterm-256color

# Update package lists and install basic tools
RUN apt-get update && apt-get install -y \
    curl \
    wget \
    git \
    python3 \
    python3-pip \
    build-essential \
    clang-format \
    clangd \
    vim \
    sigrok \
    udev \
    usbutils \
    libusb-1.0-0 \
    picocom \
    minicom \
    && rm -rf /var/lib/apt/lists/*

# Install Node.js (LTS) and Claude Code
RUN curl -fsSL https://deb.nodesource.com/setup_lts.x | bash - && \
    apt-get install -y nodejs && \
    npm install -g @anthropic-ai/claude-code && \
    rm -rf /var/lib/apt/lists/*

# Allow non-root users to access USB and serial devices
RUN echo 'SUBSYSTEM=="usb", MODE="0666"' >> /etc/udev/rules.d/99-usb.rules && \
    echo 'SUBSYSTEM=="tty", MODE="0666"' >> /etc/udev/rules.d/99-usb.rules

# Install dotfiles
COPY dotfiles/bashrc /root/.bashrc
COPY dotfiles/profile /root/.profile
COPY dotfiles/bash_aliases /root/.bash_aliases

# Optional: Import user-defined package list if it exists
COPY user-packages.txt* /tmp/
RUN if [ -f "/tmp/user-packages.txt" ]; then \
        apt-get update && \
        xargs -a /tmp/user-packages.txt apt-get install -y && \
        rm -rf /var/lib/apt/lists/*; \
    fi

# Set working directory
WORKDIR /workspace

# Default command
CMD ["/bin/bash"]
