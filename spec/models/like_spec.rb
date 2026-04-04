require "rails_helper"

RSpec.describe Like, type: :model do
  subject { build(:like) }

  describe "associations" do
    it { is_expected.to belong_to(:likeable) }
    it { is_expected.to belong_to(:user) }
  end

  describe "validations" do
    it "prevents duplicate likes by the same user on the same resource" do
      news_item = create(:news_item, :published)
      user = create(:user)
      create(:like, likeable: news_item, user: user)
      duplicate = build(:like, likeable: news_item, user: user)
      expect(duplicate).not_to be_valid
    end

    it "allows same user to like different news items" do
      user = create(:user)
      news1 = create(:news_item, :published)
      news2 = create(:news_item, :published)
      create(:like, likeable: news1, user: user)
      like2 = build(:like, likeable: news2, user: user)
      expect(like2).to be_valid
    end
  end

  describe "counter cache" do
    it "increments likes_count on news" do
      news_item = create(:news_item, :published)
      expect { create(:like, likeable: news_item) }.to change { news_item.reload.likes_count }.by(1)
    end

    it "decrements likes_count on news when destroyed" do
      like = create(:like)
      news_item = like.likeable
      expect { like.destroy }.to change { news_item.reload.likes_count }.by(-1)
    end
  end
end
