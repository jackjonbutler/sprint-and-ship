FROM node:22-slim
RUN apt-get update && apt-get install -y --no-install-recommends git curl jq ca-certificates openssh-client python3 && rm -rf /var/lib/apt/lists/*
RUN npm install -g @anthropic-ai/claude-code @notionhq/notion-mcp-server@latest
# gh CLI
RUN curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg -o /usr/share/keyrings/githubcli-archive-keyring.gpg \
 && echo "deb [signed-by=/usr/share/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" > /etc/apt/sources.list.d/github-cli.list \
 && apt-get update && apt-get install -y gh && rm -rf /var/lib/apt/lists/*
# NOTE: add flutter/other toolchains here if overnight builds must run mobile tests
WORKDIR /work
COPY server/bin /work/bin
COPY skills /root/.claude/skills
RUN chmod +x /work/bin/*
