require "rails_helper"

RSpec.describe GeolocationService do
  before { Rails.cache.clear }

  describe ".lookup" do
    it "returns nil city/country for blank IP" do
      result = described_class.lookup("")
      expect(result).to eq(city: nil, country: nil)
    end

    it "returns nil for nil IP" do
      result = described_class.lookup(nil)
      expect(result).to eq(city: nil, country: nil)
    end

    it "returns nil city/country for private IPs" do
      %w[127.0.0.1 10.0.0.1 192.168.1.1 172.16.0.1 ::1 0.0.0.0].each do |ip|
        result = described_class.lookup(ip)
        expect(result).to eq(city: nil, country: nil), "Expected nil for private IP #{ip}"
      end
    end

    it "parses successful API response" do
      stub_request(:get, %r{ip-api\.com/json/8\.8\.8\.8})
        .to_return(
          status: 200,
          body: { status: "success", city: "Ashburn", country: "United States" }.to_json,
          headers: { "Content-Type" => "application/json" }
        )

      result = described_class.lookup("8.8.8.8")
      expect(result[:city]).to eq("Ashburn")
      expect(result[:country]).to eq("United States")
    end

    it "returns nil for failed API status" do
      stub_request(:get, %r{ip-api\.com/json/1\.2\.3\.4})
        .to_return(
          status: 200,
          body: { status: "fail", message: "reserved range" }.to_json,
          headers: { "Content-Type" => "application/json" }
        )

      result = described_class.lookup("1.2.3.4")
      expect(result).to eq(city: nil, country: nil)
    end

    it "handles HTTP errors gracefully" do
      stub_request(:get, %r{ip-api\.com/json/5\.5\.5\.5})
        .to_return(status: 500, body: "Internal Server Error")

      result = described_class.lookup("5.5.5.5")
      expect(result).to eq(city: nil, country: nil)
    end

    it "handles network errors gracefully" do
      stub_request(:get, %r{ip-api\.com/json/6\.6\.6\.6})
        .to_raise(SocketError.new("Failed to open TCP connection"))

      result = described_class.lookup("6.6.6.6")
      expect(result).to eq(city: nil, country: nil)
    end

    it "uses cache key based on IP" do
      stub_request(:get, %r{ip-api\.com/json/203\.0\.113\.99})
        .to_return(status: 200, body: { status: "success", city: "Test", country: "US" }.to_json)

      allow(Rails.cache).to receive(:fetch).and_call_original
      described_class.lookup("203.0.113.99")
      expect(Rails.cache).to have_received(:fetch).with("ip_geo/203.0.113.99", hash_including(expires_in: 24.hours))
    end
  end
end
