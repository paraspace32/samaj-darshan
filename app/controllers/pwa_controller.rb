class PwaController < ApplicationController
  skip_before_action :verify_authenticity_token

  layout false

  def manifest
    manifest = {
      id: "/",
      name: I18n.t("brand.name"),
      short_name: I18n.t("brand.short_name", default: I18n.t("brand.name")),
      start_url: "/",
      scope: "/",
      display: "standalone",
      orientation: "portrait",
      background_color: "#ffffff",
      theme_color: "#ea580c",
      description: I18n.t("brand.tagline"),
      lang: I18n.locale.to_s,
      dir: "ltr",
      categories: [ "news", "social" ],
      icons: [
        { src: "/icon-192.png", sizes: "192x192", type: "image/png", purpose: "any" },
        { src: "/icon-512.png", sizes: "512x512", type: "image/png", purpose: "any" },
        { src: "/icon-192.png", sizes: "192x192", type: "image/png", purpose: "maskable" },
        { src: "/icon-512.png", sizes: "512x512", type: "image/png", purpose: "maskable" }
      ],
      prefer_related_applications: false
    }

    render json: manifest
  end

  def service_worker
    response.headers["Content-Type"] = "application/javascript"
    response.headers["Service-Worker-Allowed"] = "/"
    response.headers["Cache-Control"] = "no-cache"
    render plain: service_worker_js, layout: false
  end

  private

  def service_worker_js
    <<~JS
      const CACHE_VERSION = 'samaj-darshan-v2';
      const OFFLINE_URL = '/offline';
      const PRECACHE_URLS = [
        OFFLINE_URL,
        '/icon-192.png',
        '/icon-512.png'
      ];

      self.addEventListener('install', (event) => {
        event.waitUntil(
          caches.open(CACHE_VERSION)
            .then((cache) => cache.addAll(PRECACHE_URLS))
            .then(() => self.skipWaiting())
        );
      });

      self.addEventListener('activate', (event) => {
        event.waitUntil(
          caches.keys().then((keys) =>
            Promise.all(
              keys.filter((key) => key !== CACHE_VERSION)
                  .map((key) => caches.delete(key))
            )
          ).then(() => self.clients.claim())
        );
      });

      self.addEventListener('fetch', (event) => {
        if (event.request.method !== 'GET') return;

        if (event.request.mode === 'navigate') {
          event.respondWith(
            fetch(event.request).catch(() => caches.match(OFFLINE_URL))
          );
          return;
        }

        event.respondWith(
          caches.match(event.request).then((cached) => {
            return cached || fetch(event.request).then((response) => {
              if (response.ok && event.request.url.match(/\\.(png|svg|css|js|woff2?)$/)) {
                const clone = response.clone();
                caches.open(CACHE_VERSION).then((cache) => cache.put(event.request, clone));
              }
              return response;
            }).catch(() => caches.match(OFFLINE_URL));
          })
        );
      });
    JS
  end
end
