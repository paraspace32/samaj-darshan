require "rails_helper"

RSpec.describe Category, type: :model do
  subject { build(:category) }

  describe "associations" do
    it { is_expected.to have_many(:articles).dependent(:restrict_with_error) }
  end

  describe "validations" do
    it { is_expected.to validate_presence_of(:name_en) }
    it { is_expected.to validate_uniqueness_of(:name_en) }
    it { is_expected.to validate_presence_of(:name_hi) }
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
