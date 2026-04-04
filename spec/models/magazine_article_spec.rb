require "rails_helper"

RSpec.describe MagazineArticle, type: :model do
  subject { build(:magazine_article) }

  describe "associations" do
    it { is_expected.to belong_to(:magazine) }
    it { is_expected.to belong_to(:author).class_name("User") }
  end

  describe "validations" do
    it { is_expected.to validate_presence_of(:title_en) }
    it { is_expected.to validate_presence_of(:title_hi) }
    it { is_expected.to validate_presence_of(:content_en) }
    it { is_expected.to validate_presence_of(:content_hi) }
    it { is_expected.to validate_presence_of(:position) }
    it { is_expected.to validate_numericality_of(:position).is_greater_than_or_equal_to(0) }
  end

  describe "scopes" do
    let(:magazine) { create(:magazine) }

    it ".ordered returns articles by position asc" do
      a2 = create(:magazine_article, magazine: magazine, position: 2)
      a0 = create(:magazine_article, magazine: magazine, position: 0)
      a1 = create(:magazine_article, magazine: magazine, position: 1)
      expect(MagazineArticle.ordered).to eq([a0, a1, a2])
    end
  end
end
