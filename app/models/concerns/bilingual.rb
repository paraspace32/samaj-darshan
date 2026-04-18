module Bilingual
  extend ActiveSupport::Concern

  included do
    before_validation :fill_bilingual_fallbacks
  end

  class_methods do
    def bilingual_field(*fields)
      @bilingual_fields ||= []
      @bilingual_fields |= fields.map(&:to_sym)

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

    def bilingual_fields
      @bilingual_fields || []
    end
  end

  private

  # Auto-fill the missing language from whichever is present
  def fill_bilingual_fallbacks
    self.class.bilingual_fields.each do |field|
      en_val = send(:"#{field}_en")
      hi_val = send(:"#{field}_hi")
      send(:"#{field}_hi=", en_val) if hi_val.blank? && en_val.present?
      send(:"#{field}_en=", hi_val) if en_val.blank? && hi_val.present?
    end
  end
end
