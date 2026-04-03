require "rails_helper"

RSpec.describe Like, type: :model do
  subject { build(:like) }

  describe "associations" do
    it { is_expected.to belong_to(:likeable) }
    it { is_expected.to belong_to(:user) }
  end

  describe "validations" do
    it "prevents duplicate likes by the same user on the same resource" do
      article = create(:article, :published)
      user = create(:user)
      create(:like, likeable: article, user: user)
      duplicate = build(:like, likeable: article, user: user)
      expect(duplicate).not_to be_valid
    end

    it "allows same user to like different articles" do
      user = create(:user)
      article1 = create(:article, :published)
      article2 = create(:article, :published)
      create(:like, likeable: article1, user: user)
      like2 = build(:like, likeable: article2, user: user)
      expect(like2).to be_valid
    end
  end

  describe "counter cache" do
    it "increments likes_count on article" do
      article = create(:article, :published)
      expect { create(:like, likeable: article) }.to change { article.reload.likes_count }.by(1)
    end

    it "decrements likes_count on article when destroyed" do
      like = create(:like)
      article = like.likeable
      expect { like.destroy }.to change { article.reload.likes_count }.by(-1)
    end
  end
end
