module AuthHelpers
  def login_as(user)
    post login_path, params: { phone: user.phone, firebase_id_token: "test_token" }, as: :json
  end
end

RSpec.configure do |config|
  config.include AuthHelpers, type: :request
end
