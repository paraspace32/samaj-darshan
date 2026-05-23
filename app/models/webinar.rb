class Webinar < ApplicationRecord
  include Bilingual
  bilingual_field :title, :description

  belongs_to :host, class_name: "User"

  has_one_attached :cover_image do |attachable|
    attachable.variant :hero,  resize_to_limit: [ 1600, 800 ], format: :webp, saver: { quality: 85 }
    attachable.variant :card,  resize_to_limit: [ 800, 450 ],  format: :webp, saver: { quality: 80 }
    attachable.variant :thumb, resize_to_limit: [ 200, 140 ],  format: :webp, saver: { quality: 75 }
    attachable.variant :og,    resize_to_fill: [ 1200, 800 ],  format: :jpeg, saver: { quality: 80 }
  end

  enum :status, { draft: 0, published: 1, cancelled: 2 }
  enum :platform, { zoom: 0, google_meet: 1, youtube_live: 2, other: 3, zoho: 4 }

  validates :title_en,       presence: true
  validates :description_en, presence: true
  validates :speaker_name, presence: true
  validates :starts_at, presence: true
  validates :duration_minutes, presence: true, numericality: { greater_than: 0 }

  scope :visible, -> { published.order(starts_at: :asc) }
  scope :upcoming, -> { visible.where("starts_at > ?", Time.current) }
  scope :past, -> { visible.where("starts_at <= ?", Time.current) }

  def upcoming?
    starts_at > Time.current
  end

  def live_now?
    starts_at <= Time.current && ends_at > Time.current
  end

  def ended?
    ends_at <= Time.current
  end

  def ends_at
    starts_at + duration_minutes.minutes
  end

  def platform_label
    platform.humanize
  end

  def embeddable?
    youtube_embed_url.present?
  end

  # Extracts the Zoho session ID from the registration URL
  # e.g. "https://webinar.zoho.in/meeting/register?sessionId=1385865660" => "1385865660"
  def zoho_session_id
    return nil if registration_url.blank?

    uri = URI.parse(registration_url.strip)
    params = URI.decode_www_form(uri.query || "").to_h
    params["sessionId"]
  rescue URI::InvalidURIError
    nil
  end

  def youtube_embed_url
    return nil if meeting_url.blank?

    video_id = case meeting_url
    when %r{youtu\.be/([^?&/]+)}          then Regexp.last_match(1)
    when %r{youtube\.com/live/([^?&/]+)}   then Regexp.last_match(1)
    when %r{youtube\.com.*[?&]v=([^&]+)}   then Regexp.last_match(1)
    when %r{youtube\.com/embed/([^?&/]+)}  then Regexp.last_match(1)
    end

    "https://www.youtube.com/embed/#{video_id}" if video_id
  end

  def joinable?
    meeting_url.present? && (live_now? || starts_within_15_min?)
  end

  def starts_within_15_min?
    upcoming? && starts_at <= 15.minutes.from_now
  end

  # Determines what the show page should display as the primary action.
  #
  # Returns a symbol:
  #   :registration  — upcoming + has Zoho/external registration URL
  #   :youtube_live  — live now or upcoming + YouTube embed available
  #   :join_link     — live/upcoming + non-YouTube meeting URL
  #   :recording     — ended + YouTube embed available (saved recording)
  #   :ended         — ended, no recording
  #   :info          — upcoming, no links configured
  def primary_action
    if upcoming? || live_now?
      if registration_url.present? && upcoming?
        :registration
      elsif embeddable?
        :youtube_live
      elsif meeting_url.present?
        :join_link
      else
        :info
      end
    else
      embeddable? ? :recording : :ended
    end
  end
end
