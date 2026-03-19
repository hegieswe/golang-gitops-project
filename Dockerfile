# Stage 1: Build stage
FROM golang:tip-alpine3.23 AS builder

# Set working directory
WORKDIR /app

# Copy source code
COPY . .

# Build aplikasi secara statis
RUN CGO_ENABLED=0 GOOS=linux go build -o my-app main.go

# Stage 2: Final stage (Runtime)
FROM alpine:3.23.3

# Install ca-certificates untuk koneksi HTTPS jika diperlukan
RUN apk --no-cache add ca-certificates

WORKDIR /root/

# Copy binary dari stage builder
COPY --from=builder /app/my-app .

# Expose port aplikasi
EXPOSE 8080

# Jalankan aplikasi
CMD ["./my-app"]