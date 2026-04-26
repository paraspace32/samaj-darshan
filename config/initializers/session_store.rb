# Keep users logged in for 30 days even after the browser is closed.
# Rails 8.1 uses encrypted cookie sessions by default (CookieStore).
# Without expire_after the cookie is a "session cookie" that disappears
# when the browser is closed — which is why users have to log in again
# every time they reopen the app / PWA.
Rails.application.config.session_store :cookie_store,
  key: "_samaj_darshan_session",
  expire_after: 30.days,
  secure: Rails.env.production?,
  same_site: :lax
