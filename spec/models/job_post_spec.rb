require "rails_helper"

RSpec.describe JobPost, type: :model do
  describe "validations" do
    it { is_expected.to validate_presence_of(:title_en) }
    it { is_expected.to validate_presence_of(:title_hi) }
    it { is_expected.to validate_presence_of(:description_en) }
    it { is_expected.to validate_presence_of(:description_hi) }
    it { is_expected.to validate_presence_of(:company_name) }
  end

  describe "associations" do
    it { is_expected.to belong_to(:author).class_name("User") }
  end

  describe "enums" do
    it { is_expected.to define_enum_for(:status).with_values(draft: 0, published: 1) }
    it {
      is_expected.to define_enum_for(:category).with_values(
        internship: 0, full_time: 1, part_time: 2,
        contract: 3, government: 4, other_job: 5
      ).with_prefix(:category)
    }
  end

  describe "scopes" do
    let!(:published_post) { create(:job_post, :published) }
    let!(:draft_post) { create(:job_post) }

    it "visible returns only published posts" do
      expect(JobPost.visible).to include(published_post)
      expect(JobPost.visible).not_to include(draft_post)
    end

    it "by_category filters by category" do
      full_time = create(:job_post, :published, :full_time)
      expect(JobPost.by_category(:full_time)).to include(full_time)
      expect(JobPost.by_category(:full_time)).not_to include(published_post)
    end
  end

  describe "#publish!" do
    it "sets status to published and sets published_at" do
      post = create(:job_post)
      post.publish!
      expect(post.published?).to be true
      expect(post.published_at).to be_present
    end
  end

  describe "#category_label" do
    it "returns humanized category" do
      post = build(:job_post, category: :internship)
      expect(post.category_label).to eq("Internship")
    end
  end

  describe "#deadline_passed?" do
    it "returns true when deadline is in the past" do
      post = build(:job_post, deadline: 1.week.ago.to_date)
      expect(post.deadline_passed?).to be true
    end

    it "returns false when deadline is in the future" do
      post = build(:job_post, deadline: 1.week.from_now.to_date)
      expect(post.deadline_passed?).to be false
    end

    it "returns false when deadline is nil" do
      post = build(:job_post, deadline: nil)
      expect(post.deadline_passed?).to be false
    end
  end
end
