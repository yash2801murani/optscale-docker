# --- Base Stage ---
ARG IMAGE=node:22.16.0-alpine3.21

FROM $IMAGE AS base

RUN npm install -g pnpm@10.12.1
  
ENV NODE_ENV production

# --- Setup project source stage ---
FROM base AS source

WORKDIR /usr/src/app

COPY ngui/package.json ngui/pnpm-lock.yaml ngui/pnpm-workspace.yaml ngui/.npmrc ./
COPY ngui/server/package.json ./server/package.json
COPY ngui/ui/package.json ./ui/package.json
COPY ngui/ ./

RUN pnpm install --frozen-lockfile --ignore-scripts

# --- Build stage ---
FROM source AS builder

WORKDIR /usr/src/app

RUN pnpm run -r build && \
    if [ -d ./build ] && [ ! -d ./ui/build ]; then mkdir -p ./ui && mv ./build ./ui/build; fi && \
    if [ -d ./dist ] && [ ! -d ./server/dist ]; then mkdir -p ./server && mv ./dist ./server/dist; fi

# Keep the workspace install from the build stage.
# The production image copies the root node_modules so the server can resolve
# workspace and runtime dependencies without relying on pnpm deploy semantics.

# --- Production Stage ---
FROM base AS production

WORKDIR /usr/src/app

# server
COPY --from=builder /usr/src/app/server/dist ./server/dist
COPY --from=builder /usr/src/app/node_modules ./node_modules

# ui
COPY --from=builder /usr/src/app/ui/build ./ui/build

# prepare-and-run.sh
COPY --from=builder /usr/src/app/prepare-and-run.sh ./prepare-and-run.sh

RUN chmod +x ./prepare-and-run.sh

EXPOSE 4000

CMD ["./prepare-and-run.sh"]
