# Backend API - run on cloud (Render, Railway, Fly.io, or any Docker host)
# Build: docker build -t tripoli-api .
# Run:   docker run -p 3000:3000 -e DATABASE_URL=... -e JWT_SECRET=... -e CORS_ORIGIN=... tripoli-api

FROM node:20-alpine

WORKDIR /app

COPY package*.json ./
RUN npm ci --omit=dev

COPY . .
# .dockerignore excludes node_modules, .env, etc.

ENV NODE_ENV=production
EXPOSE 3000

CMD ["node", "src/index.js"]
