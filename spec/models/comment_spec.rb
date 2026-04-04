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
      news_item = create(:news_item, :published)
      old = create(:comment, commentable: news_item, created_at: 2.days.ago)
      recent = create(:comment, commentable: news_item, created_at: 1.hour.ago)
      expect(news_item.comments.recent).to eq([ recent, old ])
    end
  end

  describe "counter cache" do
    it "increments comments_count on news" do
      news_item = create(:news_item, :published)
      expect { create(:comment, commentable: news_item) }.to change { news_item.reload.comments_count }.by(1)
    end

    it "decrements comments_count on news when destroyed" do
      comment = create(:comment)
      news_item = comment.commentable
      expect { comment.destroy }.to change { news_item.reload.comments_count }.by(-1)
    end
  end
end
