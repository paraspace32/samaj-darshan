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
end
