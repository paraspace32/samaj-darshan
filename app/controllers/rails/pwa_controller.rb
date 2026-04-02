module Rails
  class PwaController < ActionController::Base
    protect_from_forgery with: :null_session

    def manifest
      manifest = {
        name: I18n.t("brand.name"),
        short_name: I18n.t("brand.name"),
        start_url: root_path,
        display: "standalone",
        background_color: "#ffffff",
        theme_color: "#ea580c",
        description: I18n.t("brand.tagline"),
        icons: [
          { src: "#{request.base_url}/icon-192.png", sizes: "192x192", type: "image/png" },
          { src: "#{request.base_url}/icon-512.png", sizes: "512x512", type: "image/png" }
        ],
        prefer_related_applications: false
      }

      render json: manifest
    end

    def service_worker
      response.headers["Content-Type"] = "application/javascript"
      render plain: service_worker_js
    end

    private

    def service_worker_js
      <<~JS
        const CACHE_NAME = 'samaj-darshan-v1';
        const OFFLINE_URL = '/offline';

        self.addEventListener('install', (event) => {
          event.waitUntil(
            caches.open(CACHE_NAME).then((cache) => cache.addAll([OFFLINE_URL]))
          );
          self.skipWaiting();
        });

        self.addEventListener('fetch', (event) => {
          if (event.request.method !== 'GET') return;
          event.respondWith(
            fetch(event.request).catch(() => caches.match(event.request).then((r) => r || caches.match(OFFLINE_URL)))
          );
        });
      JS
    end
  end
end

