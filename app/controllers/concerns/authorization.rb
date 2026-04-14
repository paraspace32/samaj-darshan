module Authorization
  extend ActiveSupport::Concern

  class NotAuthorizedError < StandardError; end

  included do
    rescue_from NotAuthorizedError, with: :handle_not_authorized
  end

  private

  def require_role(*roles)
    unless current_user && roles.any? { |r| current_user.public_send(:"#{r}?") }
      raise NotAuthorizedError
    end
  end

  def authorize(ability)
    raise NotAuthorizedError unless current_user&.public_send(ability)
  end

  def require_super_admin
    require_role :super_admin
  end

  def require_admin_panel_access
    raise NotAuthorizedError unless current_user&.admin_panel_access?
  end

  def require_content_creator
    raise NotAuthorizedError unless current_user&.can_create_news?
  end

  def require_editor_access
    raise NotAuthorizedError unless current_user&.can_review?
  end

  def require_billboard_access
    raise NotAuthorizedError unless current_user&.can_manage_billboards?
  end

  def require_biodata_manager
    raise NotAuthorizedError unless current_user&.can_manage_biodatas?
  end

  def require_biodata_reviewer
    raise NotAuthorizedError unless current_user&.can_review_biodatas?
  end

  def require_biodata_delete
    raise NotAuthorizedError unless current_user&.can_delete_biodatas?
  end

  def require_magazine_access
    raise NotAuthorizedError unless current_user&.can_manage_magazines?
  end

  def handle_not_authorized
    if request.format.json?
      render json: { error: "Not authorized" }, status: :forbidden
    else
      redirect_to root_path, alert: I18n.t("flash.not_authorized", default: "You are not authorized to perform this action.")
    end
  end
end
