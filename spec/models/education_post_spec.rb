require "rails_helper"

RSpec.describe EducationPost, type: :model do
  describe "validations" do
    it { is_expected.to validate_presence_of(:title_en) }
    it { is_expected.to validate_presence_of(:title_hi) }
    it { is_expected.to validate_presence_of(:content_en) }
    it { is_expected.to validate_presence_of(:content_hi) }
  end

  describe "associations" do
    it { is_expected.to belong_to(:author).class_name("User") }
  end

  describe "enums" do
    it { is_expected.to define_enum_for(:status).with_values(draft: 0, published: 1) }
    it {
      is_expected.to define_enum_for(:category).with_values(
        competitive_exam: 0, board_exam: 1, entrance_exam: 2,
        scholarship: 3, result: 4, other_education: 5, degree_news: 6
      ).with_prefix(:category)
    }
  end

  describe "scopes" do
    let!(:published_post) { create(:education_post, :published) }
    let!(:draft_post) { create(:education_post) }

    it "visible returns only published posts" do
      expect(EducationPost.visible).to include(published_post)
      expect(EducationPost.visible).not_to include(draft_post)
    end

    it "by_category filters by category" do
      board = create(:education_post, :published, :board_exam)
      expect(EducationPost.by_category(:board_exam)).to include(board)
      expect(EducationPost.by_category(:board_exam)).not_to include(published_post)
    end
  end

  describe "#publish!" do
    it "sets status to published and sets published_at" do
      post = create(:education_post)
      post.publish!
      expect(post.published?).to be true
      expect(post.published_at).to be_present
    end
  end

  describe "#category_label" do
    it "returns humanized category" do
      post = build(:education_post, category: :competitive_exam)
      expect(post.category_label).to eq("Competitive exam")
    end
  end
end
