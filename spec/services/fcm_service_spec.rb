require "rails_helper"

RSpec.describe FcmService do
  describe "#push" do
    let(:service) { described_class.new }

    it "returns :ok on HTTP 200" do
      stub_request(:post, %r{fcm\.googleapis\.com/v1/projects/.+/messages:send})
        .to_return(status: 200, body: '{"name":"projects/test/messages/123"}')

      allow(Rails.application.credentials).to receive(:dig)
        .with(:firebase, :project_id).and_return("test-project")

      result = service.push(
        fcm_token: "test-token-abcdef",
        title: "Test",
        body: "Body",
        access_token: "fake-access-token"
      )
      expect(result).to eq(:ok)
    end

    it "returns :invalid on HTTP 404" do
      stub_request(:post, %r{fcm\.googleapis\.com/v1/projects/.+/messages:send})
        .to_return(status: 404, body: '{"error":"NOT_FOUND"}')

      allow(Rails.application.credentials).to receive(:dig)
        .with(:firebase, :project_id).and_return("test-project")

      result = service.push(
        fcm_token: "expired-token-abc",
        title: "Test",
        body: "Body",
        access_token: "fake-access-token"
      )
      expect(result).to eq(:invalid)
    end

    it "returns :invalid on HTTP 410" do
      stub_request(:post, %r{fcm\.googleapis\.com/v1/projects/.+/messages:send})
        .to_return(status: 410, body: '{"error":"UNREGISTERED"}')

      allow(Rails.application.credentials).to receive(:dig)
        .with(:firebase, :project_id).and_return("test-project")

      result = service.push(
        fcm_token: "gone-token-abcdef",
        title: "Test",
        body: "Body",
        access_token: "fake-access-token"
      )
      expect(result).to eq(:invalid)
    end

    it "returns :error on HTTP 500" do
      stub_request(:post, %r{fcm\.googleapis\.com/v1/projects/.+/messages:send})
        .to_return(status: 500, body: '{"error":"INTERNAL"}')

      allow(Rails.application.credentials).to receive(:dig)
        .with(:firebase, :project_id).and_return("test-project")

      result = service.push(
        fcm_token: "some-token-abcdef",
        title: "Test",
        body: "Body",
        access_token: "fake-access-token"
      )
      expect(result).to eq(:error)
    end

    it "returns :error when project_id is blank" do
      allow(Rails.application.credentials).to receive(:dig)
        .with(:firebase, :project_id).and_return(nil)
      allow(ENV).to receive(:[]).with("FIREBASE_PROJECT_ID").and_return(nil)

      result = service.push(
        fcm_token: "token-abcdefghij",
        title: "Test",
        body: "Body",
        access_token: "fake-access-token"
      )
      expect(result).to eq(:error)
    end

    it "returns :error on network failure" do
      stub_request(:post, %r{fcm\.googleapis\.com/v1/projects/.+/messages:send})
        .to_raise(Errno::ECONNREFUSED)

      allow(Rails.application.credentials).to receive(:dig)
        .with(:firebase, :project_id).and_return("test-project")

      result = service.push(
        fcm_token: "net-fail-token-a",
        title: "Test",
        body: "Body",
        access_token: "fake-access-token"
      )
      expect(result).to eq(:error)
    end
  end

  describe ".broadcast" do
    it "sends to all subscriptions and removes invalid tokens" do
      valid_sub = PushSubscription.create!(token: "valid-token", platform: "web")
      invalid_sub = PushSubscription.create!(token: "bad-token", platform: "pwa")

      service_instance = instance_double(described_class)
      allow(described_class).to receive(:new).and_return(service_instance)
      allow(service_instance).to receive(:access_token).and_return("test-token")
      allow(service_instance).to receive(:push).with(hash_including(fcm_token: "valid-token")).and_return(:ok)
      allow(service_instance).to receive(:push).with(hash_including(fcm_token: "bad-token")).and_return(:invalid)

      results = described_class.broadcast(title: "Test", body: "Body")

      expect(results[:sent]).to eq(1)
      expect(results[:removed]).to eq(1)
      expect(PushSubscription.find_by(token: "bad-token")).to be_nil
    end

    it "aborts when access token is nil" do
      service_instance = instance_double(described_class)
      allow(described_class).to receive(:new).and_return(service_instance)
      allow(service_instance).to receive(:access_token).and_return(nil)

      result = described_class.broadcast(title: "Test", body: "Body")
      expect(result).to be_nil
    end
  end
end
