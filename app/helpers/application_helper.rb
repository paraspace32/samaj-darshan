module ApplicationHelper
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
