module ApplicationHelper
  # Matches http(s) URLs in plain text
  URL_PATTERN = %r{https?://[^\s<>"'\]]+}

  # Linkify a single line of plain text — HTML-escapes non-URL parts,
  # wraps URLs in styled <a> tags. Used for comment bodies.
  def linkify(text)
    return "".html_safe if text.blank?
    linkify_segment(text.to_s)
  end

  # Drop-in replacement for simple_format that ALSO auto-links URLs.
  # Normalises whitespace, wraps paragraphs in <p> tags, converts \n to <br>,
  # and makes every http(s) URL a clickable link.
  # Use everywhere editorial / user content is displayed (news, education, jobs, etc.)
  def format_with_links(text)
    return "".html_safe if text.blank?

    clean = text.to_s.gsub(/\n{3,}/, "\n\n").strip
    paragraphs = clean.split(/\n\n+/)

    html = paragraphs.map do |para|
      lines = para.split(/\n/).map { |line| linkify_segment(line) }
      "<p>#{lines.join('<br>')}</p>"
    end.join("\n")

    html.html_safe
  end

  private

  def linkify_segment(text)
    parts = text.split(/(#{URL_PATTERN})/)
    parts.map do |part|
      if part.match?(URL_PATTERN)
        safe = CGI.escapeHTML(part)
        %(<a href="#{safe}" target="_blank" rel="noopener noreferrer nofollow" ) +
          %(class="text-orange-600 underline decoration-orange-300/70 break-all hover:text-orange-700 transition-colors">#{safe}</a>)
      else
        CGI.escapeHTML(part)
      end
    end.join
  end

  public


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
