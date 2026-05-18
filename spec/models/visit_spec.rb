require "rails_helper"

RSpec.describe Visit, type: :model do
  describe "associations" do
    it { is_expected.to belong_to(:user).optional }
  end

  describe ".bot_user_agent?" do
    it "detects common bots" do
      expect(Visit.bot_user_agent?("Googlebot/2.1")).to be true
      expect(Visit.bot_user_agent?("facebookexternalhit/1.1")).to be true
      expect(Visit.bot_user_agent?("WhatsApp/2.23")).to be true
      expect(Visit.bot_user_agent?("python-requests/2.28")).to be true
      expect(Visit.bot_user_agent?(nil)).to be true
      expect(Visit.bot_user_agent?("")).to be true
    end

    it "allows real browsers" do
      expect(Visit.bot_user_agent?("Mozilla/5.0 (iPhone; CPU iPhone OS 18_5 like Mac OS X) AppleWebKit/605.1.15")).to be false
      expect(Visit.bot_user_agent?("Mozilla/5.0 (Linux; Android 10) Chrome/147.0.0.0 Mobile Safari/537.36")).to be false
    end
  end

  describe ".generate_token" do
    it "creates consistent tokens" do
      token1 = Visit.generate_token("1.2.3.4", "Chrome")
      token2 = Visit.generate_token("1.2.3.4", "Chrome")
      expect(token1).to eq(token2)
    end

    it "creates different tokens for different IPs" do
      token1 = Visit.generate_token("1.2.3.4", "Chrome")
      token2 = Visit.generate_token("5.6.7.8", "Chrome")
      expect(token1).not_to eq(token2)
    end
  end

  describe "scopes" do
    it ".human excludes bots" do
      create(:visit, bot: false)
      create(:visit, bot: true)
      expect(Visit.human.count).to eq(1)
    end

    it ".today returns today's visits" do
      create(:visit, visited_at: Time.current)
      create(:visit, visited_at: 2.days.ago)
      expect(Visit.today.count).to eq(1)
    end

    it ".unique_count counts distinct tokens" do
      create(:visit, visitor_token: "abc", visited_at: Time.current)
      create(:visit, visitor_token: "abc", visited_at: Time.current)
      create(:visit, visitor_token: "xyz", visited_at: Time.current)
      expect(Visit.unique_count).to eq(2)
    end
  end
end
