require "rails_helper"

RSpec.describe Bilingual, type: :model do
  describe ".bilingual_field" do
    let(:region) { create(:region, name_en: "Mumbai", name_hi: "मुंबई") }

    context "when locale is :en" do
      before { I18n.locale = :en }
      after { I18n.locale = I18n.default_locale }

      it "returns English name first" do
        expect(region.display_name).to eq("Mumbai")
      end

      it "falls back to Hindi when English is blank" do
        region.update_column(:name_en, "")
        expect(region.display_name).to eq("मुंबई")
      end
    end

    context "when locale is :hi" do
      before { I18n.locale = :hi }
      after { I18n.locale = I18n.default_locale }

      it "returns Hindi name first" do
        expect(region.display_name).to eq("मुंबई")
      end

      it "falls back to English when Hindi is blank" do
        region.update_column(:name_hi, "")
        expect(region.display_name).to eq("Mumbai")
      end
    end
  end
end
