package main

import (
	"fmt"
	"net/http"
)

func main() {
	// Endpoint Utama
	http.HandleFunc("/", func(w http.ResponseWriter, r *http.Request) {
		fmt.Fprintf(w, "Hello, DevOps! Aplikasi ini berjalan untuk testing CI/CD GitOps. Hegi testing")
	})

	// Endpoint untuk Liveness & Readiness Probe
	http.HandleFunc("/health", func(w http.ResponseWriter, r *http.Request) {
		// Di sini kamu bisa menambahkan logika cek database atau service lain
		// Untuk saat ini, kita set selalu sehat (HTTP 200)
		w.WriteHeader(http.StatusOK)
		fmt.Fprintf(w, "OK")
	})

	fmt.Println("Server berjalan di port 8080...")
	if err := http.ListenAndServe(":8080", nil); err != nil {
		fmt.Printf("Gagal menjalankan server: %s\n", err)
	}
}