require "rails_helper"

RSpec.describe PushNotificationLog, type: :model do
  describe "validations" do
    it { is_expected.to validate_presence_of(:title) }
  end

  describe "associations" do
    it { is_expected.to belong_to(:triggered_by).class_name("User").optional }
  end

  describe "scopes" do
    it ".recent orders by created_at desc" do
      old = PushNotificationLog.create!(title: "Old", created_at: 1.day.ago)
      recent = PushNotificationLog.create!(title: "Recent", created_at: Time.current)
      expect(PushNotificationLog.recent.first).to eq(recent)
    end
  end

  describe "#delivery_rate" do
    it "returns percentage of sent vs total" do
      log = PushNotificationLog.new(sent_count: 80, total_subscribers: 100)
      expect(log.delivery_rate).to eq(80.0)
    end

    it "returns 0 when total_subscribers is zero" do
      log = PushNotificationLog.new(sent_count: 0, total_subscribers: 0)
      expect(log.delivery_rate).to eq(0)
    end

    it "rounds to one decimal" do
      log = PushNotificationLog.new(sent_count: 1, total_subscribers: 3)
      expect(log.delivery_rate).to eq(33.3)
    end
  end
end
