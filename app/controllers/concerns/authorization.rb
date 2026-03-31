module Authorization
  extend ActiveSupport::Concern

  class NotAuthorizedError < StandardError; end

  included do
    rescue_from NotAuthorizedError, with: :handle_not_authorized
  end

  private

  # Require the user to have one of the given roles
  #   require_role :super_admin, :admin
  def require_role(*roles)
    unless current_user && roles.any? { |r| current_user.public_send(:"#{r}?") }
      raise NotAuthorizedError
    end
  end

  # Require the user to pass a named ability check on User model
  #   authorize :can_publish?
  def authorize(ability)
    raise NotAuthorizedError unless current_user&.public_send(ability)
  end

  # Require super_admin for dangerous operations (user management, etc.)
  def require_super_admin
    require_role :super_admin
  end

  # Require admin or above (admin panel access)
  def require_admin_access
    require_role :super_admin, :admin
  end

  # Require editor or above (content moderation)
  def require_editor_access
    require_role :super_admin, :admin, :editor
  end

  def handle_not_authorized
    if request.format.json?
      render json: { error: "Not authorized" }, status: :forbidden
    else
      redirect_to root_path, alert: I18n.t("flash.not_authorized", default: "You are not authorized to perform this action.")
    end
  end
end
