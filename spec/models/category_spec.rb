require "rails_helper"

RSpec.describe Category, type: :model do
  subject { build(:category) }

  describe "associations" do
    it { is_expected.to have_many(:news).dependent(:restrict_with_error) }
  end

  describe "validations" do
    it "is invalid without name_en when name_hi is also blank" do
      category = build(:category, name_en: nil, name_hi: nil)
      expect(category).not_to be_valid
      expect(category.errors[:name_en]).to be_present
    end

    it { is_expected.to validate_uniqueness_of(:name_en) }

    it "is invalid without name_hi when name_en is also blank" do
      category = build(:category, name_en: nil, name_hi: nil)
      expect(category).not_to be_valid
      expect(category.errors[:name_hi]).to be_present
    end

    it { is_expected.to validate_uniqueness_of(:name_hi).case_insensitive }
    it { is_expected.to validate_uniqueness_of(:slug) }
    it { is_expected.to validate_presence_of(:color) }
  end

  describe "slug generation" do
    it "auto-generates slug from name_en when slug is blank" do
      category = build(:category, name_en: "Breaking News", slug: nil)
      category.valid?
      expect(category.slug).to eq("breaking-news")
    end
  end

  describe "scopes" do
    let!(:active) { create(:category, active: true) }
    let!(:inactive) { create(:category, active: false) }

    it ".active returns only active categories" do
      expect(Category.active).to include(active)
      expect(Category.active).not_to include(inactive)
    end
  end
end
