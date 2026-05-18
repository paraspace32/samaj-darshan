require "rails_helper"

RSpec.describe Flower, type: :model do
  describe "associations" do
    it { is_expected.to belong_to(:tribute) }
    it { is_expected.to belong_to(:user) }
  end

  describe "validations" do
    it "enforces one flower per user per tribute" do
      tribute = create(:tribute)
      user = create(:user)
      create(:flower, tribute: tribute, user: user)

      duplicate = build(:flower, tribute: tribute, user: user)
      expect(duplicate).not_to be_valid
      expect(duplicate.errors[:user_id]).to be_present
    end

    it "allows same user to give flowers to different tributes" do
      user = create(:user)
      tribute1 = create(:tribute)
      tribute2 = create(:tribute)

      create(:flower, tribute: tribute1, user: user)
      flower2 = build(:flower, tribute: tribute2, user: user)
      expect(flower2).to be_valid
    end
  end

  describe "counter_cache" do
    it "increments flowers_count on tribute" do
      tribute = create(:tribute)
      expect { create(:flower, tribute: tribute) }.to change { tribute.reload.flowers_count }.by(1)
    end

    it "decrements flowers_count on destroy" do
      flower = create(:flower)
      tribute = flower.tribute
      expect { flower.destroy }.to change { tribute.reload.flowers_count }.by(-1)
    end
  end
end
