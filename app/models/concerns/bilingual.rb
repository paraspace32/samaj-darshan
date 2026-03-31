module Bilingual
  extend ActiveSupport::Concern

  class_methods do
    def bilingual_field(*fields)
      fields.each do |field|
        define_method(:"display_#{field}") do
          if I18n.locale == :hi
            send(:"#{field}_hi").presence || send(:"#{field}_en")
          else
            send(:"#{field}_en").presence || send(:"#{field}_hi")
          end
        end
      end
    end
  end
end
