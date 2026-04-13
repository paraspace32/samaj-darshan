require "rails_helper"

RSpec.describe "Hindi locale translations", type: :model do
  describe "ActiveRecord error messages" do
    %w[taken blank invalid too_short too_long confirmation not_a_number present inclusion exclusion].each do |key|
      it "has Hindi translation for activerecord.errors.messages.#{key}" do
        translation = I18n.t("activerecord.errors.messages.#{key}", locale: :hi, count: 5)
        expect(translation).not_to include("translation missing")
      end
    end

    %w[taken blank invalid too_short too_long confirmation not_a_number present inclusion exclusion].each do |key|
      it "has Hindi translation for errors.messages.#{key}" do
        translation = I18n.t("errors.messages.#{key}", locale: :hi, count: 5)
        expect(translation).not_to include("translation missing")
      end
    end
  end

  describe "User model attribute translations" do
    %w[name phone email password password_confirmation role status].each do |attr|
      it "has Hindi translation for user attribute '#{attr}'" do
        translation = I18n.t("activerecord.attributes.user.#{attr}", locale: :hi)
        expect(translation).not_to include("translation missing")
      end
    end
  end

  describe "User model-specific error messages" do
    it "has Hindi translation for phone taken" do
      translation = I18n.t("activerecord.errors.models.user.attributes.phone.taken", locale: :hi)
      expect(translation).not_to include("translation missing")
    end

    it "has Hindi translation for phone blank" do
      translation = I18n.t("activerecord.errors.models.user.attributes.phone.blank", locale: :hi)
      expect(translation).not_to include("translation missing")
    end

    it "has Hindi translation for phone invalid" do
      translation = I18n.t("activerecord.errors.models.user.attributes.phone.invalid", locale: :hi)
      expect(translation).not_to include("translation missing")
    end

    it "has Hindi translation for email taken" do
      translation = I18n.t("activerecord.errors.models.user.attributes.email.taken", locale: :hi)
      expect(translation).not_to include("translation missing")
    end

    it "has Hindi translation for email invalid" do
      translation = I18n.t("activerecord.errors.models.user.attributes.email.invalid", locale: :hi)
      expect(translation).not_to include("translation missing")
    end

    it "has Hindi translation for name blank" do
      translation = I18n.t("activerecord.errors.models.user.attributes.name.blank", locale: :hi)
      expect(translation).not_to include("translation missing")
    end

    it "has Hindi translation for password blank" do
      translation = I18n.t("activerecord.errors.models.user.attributes.password.blank", locale: :hi)
      expect(translation).not_to include("translation missing")
    end

    it "has Hindi translation for password too_short" do
      translation = I18n.t("activerecord.errors.models.user.attributes.password.too_short", locale: :hi, count: 6)
      expect(translation).not_to include("translation missing")
    end

    it "has Hindi translation for password_confirmation confirmation" do
      translation = I18n.t("activerecord.errors.models.user.attributes.password_confirmation.confirmation", locale: :hi)
      expect(translation).not_to include("translation missing")
    end
  end

  describe "User validation full_messages in Hindi" do
    around do |example|
      original_locale = I18n.locale
      I18n.locale = :hi
      example.run
      I18n.locale = original_locale
    end

    it "generates Hindi full message for phone taken (no 'Translation missing')" do
      create(:user, phone: "9876543210")
      user = build(:user, phone: "9876543210")
      user.valid?
      messages = user.errors.full_messages.join(" ")
      expect(messages).not_to include("Translation missing")
      expect(messages).not_to include("translation missing")
    end

    it "generates Hindi full message for blank name" do
      user = build(:user, name: "")
      user.valid?
      messages = user.errors.full_messages.join(" ")
      expect(messages).not_to include("Translation missing")
      expect(messages).not_to include("translation missing")
    end

    it "generates Hindi full message for blank phone" do
      user = build(:user, phone: "")
      user.valid?
      messages = user.errors.full_messages.join(" ")
      expect(messages).not_to include("Translation missing")
      expect(messages).not_to include("translation missing")
    end

    it "generates Hindi full message for invalid phone format" do
      user = build(:user, phone: "0000000000")
      user.valid?
      messages = user.errors.full_messages.join(" ")
      expect(messages).not_to include("Translation missing")
      expect(messages).not_to include("translation missing")
    end

    it "generates Hindi full message for duplicate email" do
      create(:user, email: "test@example.com")
      user = build(:user, email: "test@example.com")
      user.valid?
      messages = user.errors.full_messages.join(" ")
      expect(messages).not_to include("Translation missing")
      expect(messages).not_to include("translation missing")
    end

    it "generates Hindi full message for invalid email" do
      user = build(:user, email: "bad-email")
      user.valid?
      messages = user.errors.full_messages.join(" ")
      expect(messages).not_to include("Translation missing")
      expect(messages).not_to include("translation missing")
    end

    it "uses Hindi attribute name in full messages" do
      user = build(:user, phone: "")
      user.valid?
      phone_attr = I18n.t("activerecord.attributes.user.phone", locale: :hi)
      phone_messages = user.errors.full_messages.select { |m| m.include?(phone_attr) }
      expect(phone_messages).not_to be_empty
    end
  end

  describe "signup form translation keys" do
    %w[title header sub success already_registered name_label phone_label
       email_label password_label password_confirm_label submit
       error_singular errors_plural errors_found].each do |key|
      it "has Hindi translation for signup.#{key}" do
        translation = I18n.t("signup.#{key}", locale: :hi)
        expect(translation).not_to include("translation missing")
      end

      it "has English translation for signup.#{key}" do
        translation = I18n.t("signup.#{key}", locale: :en)
        expect(translation).not_to include("translation missing")
      end
    end
  end

  describe "locale parity for signup keys" do
    it "has the same signup keys in both en and hi locales" do
      en_keys = flatten_keys(I18n.t("signup", locale: :en))
      hi_keys = flatten_keys(I18n.t("signup", locale: :hi))
      expect(hi_keys).to match_array(en_keys)
    end
  end

  private

  def flatten_keys(hash, prefix = "")
    return [prefix] unless hash.is_a?(Hash)

    hash.flat_map do |k, v|
      new_prefix = prefix.empty? ? k.to_s : "#{prefix}.#{k}"
      flatten_keys(v, new_prefix)
    end
  end
end
