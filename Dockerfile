# 多阶段构建：第一阶段 - 构建
FROM node:18-alpine AS builder

WORKDIR /app

# 启用 pnpm
RUN npm install -g pnpm@10.30.2

# 复制 workspace 配置文件
COPY pnpm-workspace.yaml pnpm-lock.yaml package.json ./

# 复制 core 和 web 包
COPY core ./core
COPY web ./web

# 安装所有依赖
RUN pnpm install --frozen-lockfile

# 构建前端
RUN pnpm build:web

# ============================================
# 多阶段构建：第二阶段 - 运行时
FROM node:18-alpine

WORKDIR /app

# 安装 dumb-init 处理信号
RUN apk add --no-cache dumb-init

# 启用 pnpm
RUN npm install -g pnpm@10.30.2

# 从构建阶段复制文件
COPY --from=builder /app/package.json ./
COPY --from=builder /app/pnpm-workspace.yaml ./
COPY --from=builder /app/pnpm-lock.yaml ./
COPY --from=builder /app/core ./core
COPY --from=builder /app/web/dist ./web/dist

# 安装运行时依赖（跳过开发依赖）
RUN cd core && pnpm install --prod --frozen-lockfile

# 暴露的端口
EXPOSE 3000

# 设置环境变量
ENV NODE_ENV=production
ENV ADMIN_PORT=3000
ENV ADMIN_HOST=0.0.0.0

# 使用 dumb-init 启动应用
ENTRYPOINT ["dumb-init", "--"]
CMD ["pnpm", "-C", "core", "start"]
