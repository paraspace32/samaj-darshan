module Api
  module V1
    module Admin
      class BaseController < Api::V1::BaseController
        before_action :require_api_auth
        before_action :require_admin_access
      end
    end
  end
end
