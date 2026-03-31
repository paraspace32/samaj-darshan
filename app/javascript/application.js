// Configure your import map in config/importmap.rb. Read more: https://github.com/rails/importmap-rails
import "@hotwired/turbo-rails"
import "controllers"

// Register PWA service worker
if ("serviceWorker" in navigator) {
  navigator.serviceWorker.register("/service-worker.js")
}
