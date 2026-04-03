module AuthHelpers
  def login_as(user)
    post login_path, params: { phone: user.phone, password: "password123" }
  end
end

RSpec.configure do |config|
  config.include AuthHelpers, type: :request
end
