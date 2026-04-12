module ApplicationHelper
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
