module Admin
  class BaseController < ApplicationController
    layout "admin"

    before_action :require_login
    before_action :require_active_account
    before_action :require_admin_panel_access
    before_action :set_marriage_consent_count

    private

    def set_marriage_consent_count
      @marriage_consent_count = Biodata.pending_consent.count if current_user&.can_review_biodatas?
    end
  end
end
