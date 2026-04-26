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

  def firebase_messaging_sw
    response.headers["Content-Type"] = "application/javascript"
    response.headers["Service-Worker-Allowed"] = "/"
    response.headers["Cache-Control"] = "no-cache"
    render plain: firebase_messaging_sw_js, layout: false
  end

  private

  def firebase_messaging_sw_js
    config = firebase_js_config
    <<~JS
      // ── Firebase Cloud Messaging ─────────────────────────────────────────────
      importScripts('https://www.gstatic.com/firebasejs/10.12.0/firebase-app-compat.js');
      importScripts('https://www.gstatic.com/firebasejs/10.12.0/firebase-messaging-compat.js');

      firebase.initializeApp(#{config.to_json});

      const messaging = firebase.messaging();

      // Handle background messages.
      // Payload is data-only (no notification key) so the browser will NOT
      // auto-display anything — we show exactly one notification here.
      messaging.onBackgroundMessage((payload) => {
        const d     = payload.data || {};
        const title = d.title || 'समाज दर्शन';
        const opts  = {
          body:    d.body  || '',
          icon:    '/icon-login.png',
          badge:   '/icon-login.png',
          data:    { url: d.url || '/' },
          vibrate: [200, 100, 200]
        };
        if (d.image) opts.image = d.image;

        self.registration.showNotification(title, opts);
      });

      self.addEventListener('notificationclick', (event) => {
        event.notification.close();
        const url = event.notification.data?.url || '/';
        event.waitUntil(
          clients.matchAll({ type: 'window', includeUncontrolled: true }).then((clientList) => {
            for (const client of clientList) {
              if (client.url === url && 'focus' in client) return client.focus();
            }
            if (clients.openWindow) return clients.openWindow(url);
          })
        );
      });

      // ── PWA Caching (merged so only one SW controls the scope) ───────────────
      const CACHE_VERSION = 'samaj-darshan-v2';
      const OFFLINE_URL   = '/offline';
      const PRECACHE_URLS = [OFFLINE_URL, '/icon-192.png', '/icon-512.png'];

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

        // Navigate: network-first, offline fallback
        if (event.request.mode === 'navigate') {
          event.respondWith(
            fetch(event.request).catch(() => caches.match(OFFLINE_URL))
          );
          return;
        }

        // Static assets: cache-first
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

  def firebase_js_config
    creds = Rails.application.credentials.firebase || {}
    {
      apiKey:            creds[:api_key]            || ENV["FIREBASE_API_KEY"],
      authDomain:        creds[:auth_domain]         || ENV["FIREBASE_AUTH_DOMAIN"],
      projectId:         creds[:project_id]          || ENV["FIREBASE_PROJECT_ID"],
      storageBucket:     creds[:storage_bucket]      || ENV["FIREBASE_STORAGE_BUCKET"],
      messagingSenderId: creds[:messaging_sender_id] || ENV["FIREBASE_MESSAGING_SENDER_ID"],
      appId:             creds[:app_id]              || ENV["FIREBASE_APP_ID"]
    }
  end

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
