module Admin
  class UsersController < BaseController
    before_action :require_super_admin, only: [ :create, :destroy, :toggle_status ]
    before_action :set_user, only: [ :edit, :update, :destroy, :toggle_status ]

    def index
      @users = User.order(:role, :name)
      @users = @users.where(role: params[:role]) if params[:role].present?
      @users = @users.where(status: params[:status]) if params[:status].present?
      if params[:q].present?
        q = "%#{params[:q]}%"
        @users = @users.where("name ILIKE :q OR phone ILIKE :q OR email ILIKE :q", q: q)
      end
    end

    def new
      @user = User.new(role: :contributor, status: :active)
    end

    def create
      @user = User.new(user_params)
      if @user.save
        redirect_to admin_users_path, notice: "User created."
      else
        render :new, status: :unprocessable_entity
      end
    end

    def edit
    end

    def update
      filtered = user_params
      filtered = filtered.except(:password, :password_confirmation) if filtered[:password].blank?

      if @user.update(filtered)
        redirect_to admin_users_path, notice: "User updated."
      else
        render :edit, status: :unprocessable_entity
      end
    end

    def destroy
      if @user == current_user
        redirect_to admin_users_path, alert: "You cannot delete your own account."
      elsif @user.destroy
        redirect_to admin_users_path, notice: "User deleted."
      else
        redirect_to admin_users_path, alert: @user.errors.full_messages.to_sentence
      end
    end

    def toggle_status
      if @user == current_user
        redirect_to admin_users_path, alert: "You cannot block your own account."
        return
      end

      new_status = @user.account_active? ? :blocked : :active
      @user.update!(status: new_status)
      redirect_to admin_users_path, notice: "User #{new_status == :active ? 'activated' : 'blocked'}."
    end

    private

    def set_user
      @user = User.find(params[:id])
    end

    def user_params
      params.require(:user).permit(:name, :phone, :email, :password, :password_confirmation, :role, :status)
    end
  end
end
