module ApplicationHelper
  # Auto-links URLs in plain user-generated text.
  # Safely HTML-escapes all non-URL content, then wraps detected URLs in <a> tags.
  # Use instead of plain <%= text %> wherever users can type free-form content.
  URL_PATTERN = %r{https?://[^\s<>"'\]]+}

  def linkify(text)
    return "".html_safe if text.blank?

    # Split on URL boundaries (capture group keeps the URLs in the array)
    parts = text.split(/(#{URL_PATTERN})/)
    html  = parts.map do |part|
      if part.match?(URL_PATTERN)
        safe = CGI.escapeHTML(part)
        %(<a href="#{safe}" target="_blank" rel="noopener noreferrer nofollow"
             class="text-orange-600 underline decoration-orange-300/70 break-all hover:text-orange-700 transition-colors">#{safe}</a>)
      else
        CGI.escapeHTML(part)
      end
    end.join
    html.html_safe
  end


  def billboard_for(position)
    Rails.cache.fetch("billboard/#{position}", expires_in: 5.minutes) do
      Billboard.for_position(position)
    end
  end

  def billboards_for(position)
    Rails.cache.fetch("billboards/#{position}", expires_in: 5.minutes) do
      Billboard.all_for_position(position).to_a
    end
  end

  def optimized_image_tag(attachment, variant: nil, **html_opts)
    blob = attachment.respond_to?(:blob) ? attachment.blob : attachment

    source = if variant && blob.variable?
      attachment.variant(variant)
    else
      attachment
    end

    image_tag source, **html_opts
  end

  # Generate an absolute URL for an attachment's OG image variant.
  # Social media crawlers (WhatsApp, Facebook, Twitter) require absolute URLs
  # and respond best to properly-sized JPEG images.
  def og_image_url(attachment)
    return nil unless attachment.attached?

    variant = attachment.variant(:og)
    path = polymorphic_path(variant)
    URI.join(request.base_url, path).to_s
  end

  def sanitize_url(url)
    uri = URI.parse(url.to_s)
    uri.scheme.in?(%w[http https]) ? url : "#"
  rescue URI::InvalidURIError
    "#"
  end

  # Route helpers for polymorphic commentable/likeable models
  def commentable_path(record, **opts)
    case record
    when News then news_path(record, **opts)
    when EducationPost then education_path(record, **opts)
    end
  end

  def commentable_comments_path(record, **opts)
    case record
    when News then news_comments_path(record, **opts)
    when EducationPost then education_comments_path(record, **opts)
    end
  end

  def commentable_comment_path(record, comment, **opts)
    case record
    when News then news_comment_path(record, comment, **opts)
    when EducationPost then education_comment_path(record, comment, **opts)
    end
  end

  def toggle_likeable_like_path(record, **opts)
    case record
    when News then toggle_news_like_path(record, **opts)
    when EducationPost then toggle_education_like_path(record, **opts)
    end
  end
end
