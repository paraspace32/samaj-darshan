module Admin
  class BaseController < ApplicationController
    layout "admin"

    before_action :require_login
    before_action :require_active_account
    before_action :require_admin_panel_access
  end
end
