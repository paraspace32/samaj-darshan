require "rails_helper"

RSpec.describe Tribute, type: :model do
  subject { build(:tribute) }

  describe "validations" do
    it "is invalid without name_en and name_hi" do
      tribute = build(:tribute, name_en: nil, name_hi: nil)
      expect(tribute).not_to be_valid
    end

    it "is invalid without description_en and description_hi" do
      tribute = build(:tribute, description_en: nil, description_hi: nil)
      expect(tribute).not_to be_valid
    end
  end

  describe "associations" do
    it { is_expected.to belong_to(:created_by).class_name("User") }
    it { is_expected.to have_many(:flowers).dependent(:destroy) }
    it { is_expected.to have_many(:flower_givers).through(:flowers).source(:user) }
  end

  describe "bilingual fields" do
    it "returns English name when locale is :en" do
      tribute = build(:tribute, name_en: "John", name_hi: "जॉन")
      I18n.with_locale(:en) { expect(tribute.display_name).to eq("John") }
    end

    it "returns Hindi name when locale is :hi" do
      tribute = build(:tribute, name_en: "John", name_hi: "जॉन")
      I18n.with_locale(:hi) { expect(tribute.display_name).to eq("जॉन") }
    end

    it "falls back to English when Hindi is blank" do
      tribute = build(:tribute, name_en: "John", name_hi: nil)
      I18n.with_locale(:hi) { expect(tribute.display_name).to eq("John") }
    end
  end

  describe ".recent" do
    it "orders by created_at descending" do
      old_tribute = create(:tribute, created_at: 2.days.ago)
      new_tribute = create(:tribute, created_at: 1.hour.ago)
      expect(Tribute.recent).to eq([ new_tribute, old_tribute ])
    end
  end
end
