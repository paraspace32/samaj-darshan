class PushSubscription < ApplicationRecord
  belongs_to :user, optional: true

  # ── platform ─────────────────────────────────────────────────────────────────
  # "web"     → browser tab (Chrome, Firefox, etc.)
  # "pwa"     → installed PWA running in standalone mode
  # "android" → reserved for future native Android app
  # "ios"     → reserved for future native iOS app
  PLATFORMS = %w[web pwa android ios].freeze

  # ── os ───────────────────────────────────────────────────────────────────────
  # Device / operating system of the subscriber.
  OS_VALUES = %w[android ios windows macos linux unknown].freeze

  # ── display_mode ─────────────────────────────────────────────────────────────
  # How the app was opened at the time of token registration.
  # "browser"    → address bar visible (not installed)
  # "standalone" → launched from home screen / app drawer (installed PWA)
  DISPLAY_MODES = %w[browser standalone].freeze

  validates :token,        presence: true, uniqueness: true
  validates :platform,     inclusion: { in: PLATFORMS }
  validates :os,           inclusion: { in: OS_VALUES },     allow_blank: true
  validates :display_mode, inclusion: { in: DISPLAY_MODES }, allow_blank: true

  # ── Scopes ────────────────────────────────────────────────────────────────────
  scope :web,        -> { where(platform: "web") }
  scope :pwa,        -> { where(platform: "pwa") }

  scope :on_android, -> { where(os: "android") }
  scope :on_ios,     -> { where(os: "ios") }
  scope :on_desktop, -> { where(os: %w[windows macos linux]) }

  scope :standalone, -> { where(display_mode: "standalone") }
  scope :in_browser, -> { where(display_mode: "browser") }

  scope :anonymous,  -> { where(user_id: nil) }
  scope :logged_in,  -> { where.not(user_id: nil) }

  # ── Helpers ───────────────────────────────────────────────────────────────────

  # Human-readable label for logging / admin display.
  # e.g. "pwa/android/standalone", "web/windows/browser"
  def identity_label
    [ platform, os, display_mode ].join("/")
  end

  # Remove an invalid/expired token silently
  def self.remove_token(token)
    find_by(token: token)&.destroy
  end
end
