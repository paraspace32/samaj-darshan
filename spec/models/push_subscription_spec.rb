require "rails_helper"

RSpec.describe PushSubscription, type: :model do
  describe "validations" do
    subject { PushSubscription.new(token: "abc123", platform: "web") }

    it { is_expected.to validate_presence_of(:token) }
    it { is_expected.to validate_uniqueness_of(:token) }
    it { is_expected.to validate_inclusion_of(:platform).in_array(PushSubscription::PLATFORMS) }
    it { is_expected.to validate_inclusion_of(:os).in_array(PushSubscription::OS_VALUES).allow_blank }
    it { is_expected.to validate_inclusion_of(:display_mode).in_array(PushSubscription::DISPLAY_MODES).allow_blank }
  end

  describe "associations" do
    it { is_expected.to belong_to(:user).optional }
  end

  describe "scopes" do
    let(:user) { create(:user) }
    let!(:web_sub) { PushSubscription.create!(token: "t1", platform: "web", os: "windows", display_mode: "browser") }
    let!(:pwa_sub) { PushSubscription.create!(token: "t2", platform: "pwa", os: "android", display_mode: "standalone", user: user) }
    let!(:ios_sub) { PushSubscription.create!(token: "t3", platform: "ios", os: "ios") }

    it ".web returns web platform only" do
      expect(PushSubscription.web).to contain_exactly(web_sub)
    end

    it ".pwa returns pwa platform only" do
      expect(PushSubscription.pwa).to contain_exactly(pwa_sub)
    end

    it ".on_android returns android OS" do
      expect(PushSubscription.on_android).to contain_exactly(pwa_sub)
    end

    it ".on_ios returns iOS" do
      expect(PushSubscription.on_ios).to contain_exactly(ios_sub)
    end

    it ".on_desktop returns desktop OS" do
      expect(PushSubscription.on_desktop).to contain_exactly(web_sub)
    end

    it ".anonymous returns subs without user" do
      expect(PushSubscription.anonymous).to contain_exactly(web_sub, ios_sub)
    end

    it ".logged_in returns subs with user" do
      expect(PushSubscription.logged_in).to contain_exactly(pwa_sub)
    end

    it ".standalone returns standalone display_mode" do
      expect(PushSubscription.standalone).to include(pwa_sub)
      expect(PushSubscription.standalone).not_to include(web_sub)
    end

    it ".in_browser returns browser display_mode" do
      expect(PushSubscription.in_browser).to include(web_sub)
      expect(PushSubscription.in_browser).not_to include(pwa_sub)
    end
  end

  describe "#identity_label" do
    it "joins platform, os, display_mode" do
      sub = PushSubscription.new(platform: "pwa", os: "android", display_mode: "standalone")
      expect(sub.identity_label).to eq("pwa/android/standalone")
    end
  end

  describe ".remove_token" do
    it "destroys subscription by token" do
      sub = PushSubscription.create!(token: "remove-me", platform: "web")
      expect { PushSubscription.remove_token("remove-me") }.to change(PushSubscription, :count).by(-1)
    end

    it "does nothing for unknown token" do
      expect { PushSubscription.remove_token("nonexistent") }.not_to change(PushSubscription, :count)
    end
  end
end
