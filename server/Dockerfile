# AAB2APK API: Node.js + Java (for bundletool)
FROM node:20-bookworm-slim

# Java 17 for bundletool + keytool (debug keystore)
RUN apt-get update && apt-get install -y --no-install-recommends \
    openjdk-17-jdk-headless \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /app

COPY package.json package-lock.json* ./
RUN npm ci --omit=dev

COPY *.js ./
# Bundletool JAR downloaded at build time so the image is self-contained
RUN node download-bundletool.js

EXPOSE 3000
ENV PORT=3000
CMD ["node", "index.js"]
