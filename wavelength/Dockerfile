# --- Build stage ---
FROM debian:stable-slim AS build

# Install dependencies
RUN apt-get update && apt-get install -y curl git unzip xz-utils zip libglu1-mesa

# Install Flutter SDK
RUN git clone https://github.com/flutter/flutter.git /usr/local/flutter
ENV PATH="/usr/local/flutter/bin:/usr/local/flutter/bin/cache/dart-sdk/bin:${PATH}"

# Enable web
RUN flutter config --enable-web

# Copy ONLY the Flutter project into the container
WORKDIR /app
COPY wavelength/ .

# Build release version
RUN flutter build web --release

# --- Run stage ---
FROM nginx:alpine

# Copy Flutter build to Nginx web root
COPY --from=build /app/build/web /usr/share/nginx/html

EXPOSE 80
CMD ["nginx", "-g", "daemon off;"]
