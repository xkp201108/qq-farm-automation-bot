# --- 基础环境 ---
FROM node:20-alpine AS base
RUN corepack enable && corepack prepare pnpm@latest --activate
WORKDIR /app

# --- 依赖安装阶段 ---
FROM base AS deps
COPY pnpm-lock.yaml ./
COPY package.json ./
COPY core/package.json ./core/
COPY web/package.json ./web/
# 安装所有依赖
RUN pnpm install --frozen-lockfile

# --- 静态资源构建阶段 ---
FROM deps AS builder
COPY . .
# 构建前端网页 (产物会生成在 web/dist)
RUN pnpm build:web

# --- 最终运行阶段 ---
FROM base AS runner
ENV NODE_ENV=production
ENV ADMIN_PORT=3007

# 只复制必要运行文件，减小镜像体积
COPY --from=deps /app/node_modules ./node_modules
COPY --from=deps /app/core/node_modules ./core/node_modules
COPY --from=builder /app/core ./core
COPY --from=builder /app/web/dist ./web/dist
COPY --from=builder /app/package.json ./

# 暴露默认端口
EXPOSE 3007

# 启动核心服务
CMD ["pnpm", "dev:core"]
