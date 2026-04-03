require "rails_helper"

RSpec.describe Comment, type: :model do
  subject { build(:comment) }

  describe "associations" do
    it { is_expected.to belong_to(:commentable) }
    it { is_expected.to belong_to(:user) }
  end

  describe "validations" do
    it { is_expected.to validate_presence_of(:body) }
    it { is_expected.to validate_length_of(:body).is_at_most(2000) }
  end

  describe "scopes" do
    it ".recent returns comments in reverse chronological order" do
      article = create(:article, :published)
      old = create(:comment, commentable: article, created_at: 2.days.ago)
      recent = create(:comment, commentable: article, created_at: 1.hour.ago)
      expect(article.comments.recent).to eq([ recent, old ])
    end
  end

  describe "counter cache" do
    it "increments comments_count on article" do
      article = create(:article, :published)
      expect { create(:comment, commentable: article) }.to change { article.reload.comments_count }.by(1)
    end

    it "decrements comments_count on article when destroyed" do
      comment = create(:comment)
      article = comment.commentable
      expect { comment.destroy }.to change { article.reload.comments_count }.by(-1)
    end
  end
end
