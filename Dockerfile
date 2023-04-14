FROM debian:11 as base
SHELL ["/bin/bash", "-o", "pipefail", "-c"]

# Add Docker as source for apt
RUN apt-get update && apt-get install -y curl gpg lsb-release \
  && apt-get clean && rm -rf /var/lib/apt/lists/* \
  && curl -fsSL https://download.docker.com/linux/debian/gpg | gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg \
  && echo "deb [arch=amd64 signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/debian $(lsb_release -cs) stable" | tee /etc/apt/sources.list.d/docker.list > /dev/null

RUN apt-get update \
 && apt-get install -y \
    ca-certificates \
    fzf \
    git \
    jq \
    nano \
    shellcheck \
    vim-nox \
 && apt-get clean \
 && rm -rf /var/lib/apt/lists/*

WORKDIR /tmp/

ARG IJQVER=0.4.1
RUN curl \
  --url "https://git.sr.ht/~gpanders/ijq/refs/download/v$IJQVER/ijq-$IJQVER-linux-amd64.tar.gz" \
  | tar \
    --extract \
    --gunzip \
    --file - \
    --directory "/usr/local/bin/" \
    --strip-components 1 \
    "ijq-$IJQVER/ijq"

# Clean up temp dir
RUN rm -rf /tmp/*

WORKDIR /root
COPY . .
RUN cat bashrc.add >> /root/.bashrc && rm bashrc.add
ENV TERM xterm-256color

CMD ["bash"]
