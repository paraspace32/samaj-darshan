require "rails_helper"

RSpec.describe Region, type: :model do
  subject { build(:region) }

  describe "associations" do
    it { is_expected.to have_many(:articles).dependent(:restrict_with_error) }
  end

  describe "validations" do
    it { is_expected.to validate_presence_of(:name_en) }
    it { is_expected.to validate_uniqueness_of(:name_en) }
    it { is_expected.to validate_presence_of(:name_hi) }
    it { is_expected.to validate_uniqueness_of(:name_hi).case_insensitive }
    it { is_expected.to validate_uniqueness_of(:slug) }
  end

  describe "slug generation" do
    it "auto-generates slug from name_en when slug is blank" do
      region = build(:region, name_en: "New Delhi", slug: nil)
      region.valid?
      expect(region.slug).to eq("new-delhi")
    end

    it "does not overwrite an existing slug" do
      region = build(:region, name_en: "Mumbai", slug: "custom-slug")
      region.valid?
      expect(region.slug).to eq("custom-slug")
    end
  end

  describe "scopes" do
    let!(:active) { create(:region, active: true) }
    let!(:inactive) { create(:region, active: false) }

    it ".active returns only active regions" do
      expect(Region.active).to include(active)
      expect(Region.active).not_to include(inactive)
    end
  end

  describe "#to_param" do
    it "returns the slug" do
      region = build(:region, slug: "mumbai")
      expect(region.to_param).to eq("mumbai")
    end
  end
end
