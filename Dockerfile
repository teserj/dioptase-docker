FROM node:20

ARG TZ
ENV TZ="$TZ"
ARG CLAUDE_CODE_VERSION=latest
ENV DEBIAN_FRONTEND=noninteractive
ENV TERM=xterm-256color

# Install Claude Code devcontainer base + embedded dev packages
RUN apt-get update && apt-get install -y --no-install-recommends \
    less \
    git \
    procps \
    sudo \
    fzf \
    man-db \
    unzip \
    gnupg2 \
    gh \
    iptables \
    ipset \
    iproute2 \
    dnsutils \
    aggregate \
    jq \
    nano \
    vim \
    curl \
    wget \
    python3 \
    python3-pip \
    build-essential \
    clang-format \
    clangd \
    sigrok \
    udev \
    usbutils \
    libusb-1.0-0 \
    picocom \
    minicom \
    && apt-get clean && rm -rf /var/lib/apt/lists/*

# Pre-install dioptase Python dependencies at build time
RUN pip install --break-system-packages \
    "click>=8.1" "httpx>=0.27" "prompt-toolkit>=3.0" "pyserial>=3.5" "rich>=13.0" \
    hatchling

# Ensure default node user has access to /usr/local/share
RUN mkdir -p /usr/local/share/npm-global && \
    chown -R node:node /usr/local/share

# Add node user to dialout group for serial/UART access
RUN usermod -aG dialout node

# Allow non-root users to access USB and serial devices
RUN echo 'SUBSYSTEM=="usb", MODE="0666"' >> /etc/udev/rules.d/99-usb.rules && \
    echo 'SUBSYSTEM=="tty", MODE="0666"' >> /etc/udev/rules.d/99-usb.rules

# Set `DEVCONTAINER` environment variable
ENV DEVCONTAINER=true

# Create workspace and config directories
RUN mkdir -p /workspace && chown -R node:node /workspace

# Create ~/.ssh with correct permissions so known_hosts can be bind-mounted
RUN mkdir -p /home/node/.ssh && chmod 700 /home/node/.ssh && chown -R node:node /home/node/.ssh

WORKDIR /workspace

# Install global packages as node user
USER node
ENV NPM_CONFIG_PREFIX=/usr/local/share/npm-global
ENV PATH=$PATH:/usr/local/share/npm-global/bin:/home/node/.local/bin

# Install Claude Code
RUN npm install -g @anthropic-ai/claude-code@${CLAUDE_CODE_VERSION}

# Copy and set up firewall script
COPY init-firewall.sh /usr/local/bin/
USER root
RUN chmod +x /usr/local/bin/init-firewall.sh && \
    echo "node ALL=(root) NOPASSWD: /usr/local/bin/init-firewall.sh" > /etc/sudoers.d/node-firewall && \
    chmod 0440 /etc/sudoers.d/node-firewall

# Install dotfiles for node user
COPY dotfiles/bashrc /home/node/.bashrc
COPY dotfiles/profile /home/node/.profile
COPY dotfiles/bash_aliases /home/node/.bash_aliases
RUN chown node:node /home/node/.bashrc /home/node/.profile /home/node/.bash_aliases

# Optional: Import user-defined package list if it exists
COPY user-packages.txt* /tmp/
RUN if [ -f "/tmp/user-packages.txt" ]; then \
        apt-get update && \
        xargs -a /tmp/user-packages.txt apt-get install -y && \
        rm -rf /var/lib/apt/lists/*; \
    fi

USER node
CMD ["/bin/bash"]
