module Api
  module V1
    module Admin
      class UsersController < BaseController
        before_action :require_super_admin, only: [ :create, :destroy, :toggle_status ]
        before_action :set_user, only: [ :show, :update, :destroy, :toggle_status ]

        def index
          users = User.order(:role, :name)
          users = users.where(role: params[:role]) if params[:role].present?
          render json: { users: users.map { |u| user_json(u) } }
        end

        def show
          render json: { user: user_json(@user) }
        end

        def create
          user = User.create!(user_params)
          render json: { user: user_json(user) }, status: :created
        end

        def update
          filtered = user_params
          filtered = filtered.except(:password, :password_confirmation) if filtered[:password].blank?
          @user.update!(filtered)
          render json: { user: user_json(@user) }
        end

        def destroy
          if @user == current_user
            render json: { error: "Cannot delete your own account" }, status: :forbidden
            return
          end
          @user.destroy!
          render json: { message: "User deleted" }
        end

        def toggle_status
          if @user == current_user
            render json: { error: "Cannot block your own account" }, status: :forbidden
            return
          end
          new_status = @user.account_active? ? :blocked : :active
          @user.update!(status: new_status)
          render json: { user: user_json(@user), message: "User #{new_status}" }
        end

        private

        def set_user
          @user = User.find(params[:id])
        end

        def user_params
          permitted = if current_user.super_admin?
            params.require(:user).permit(:name, :phone, :email, :password, :password_confirmation, :role, :status, allowed_sections: [])
          else
            params.require(:user).permit(:name, :phone, :email, :password, :password_confirmation)
          end
          sanitize_allowed_sections(permitted)
        end

        def sanitize_allowed_sections(permitted)
          permitted[:allowed_sections] = permitted[:allowed_sections]&.reject(&:blank?) || [] if permitted.key?(:allowed_sections)
          permitted
        end

        def user_json(user)
          {
            id: user.id,
            name: user.name,
            phone: user.phone,
            email: user.email,
            role: user.role,
            status: user.status,
            allowed_sections: user.allowed_sections,
            news_count: user.news.count,
            created_at: user.created_at.iso8601
          }
        end
      end
    end
  end
end
