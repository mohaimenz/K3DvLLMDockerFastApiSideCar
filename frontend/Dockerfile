FROM node:18-alpine AS builder

WORKDIR /app

# Install deps first for better caching
COPY COPY [package.json](http://_vscodecontentref_/3) package-lock.json ./
RUN npm ci

# Then copy source and build
COPY . .
RUN npm run build

FROM nginx:alpine

COPY --from=builder /app/dist /usr/share/nginx/html

# Optional: custom nginx config
COPY nginx.conf /etc/nginx/conf.d/default.conf

EXPOSE 80

CMD ["nginx", "-g", "daemon off;"]
