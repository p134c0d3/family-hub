# frozen_string_literal: true

module Admin
  # UsersController handles admin user management
  #
  class UsersController < BaseController
    before_action :set_user, except: [:index]

    # GET /admin/users
    def index
      @users = User.order(created_at: :desc)
    end

    # GET /admin/users/:id
    def show
    end

    # GET /admin/users/:id/edit
    def edit
    end

    # PATCH /admin/users/:id
    def update
      if @user.update(user_params)
        redirect_to admin_user_path(@user), notice: "User updated successfully."
      else
        render :edit, status: :unprocessable_entity
      end
    end

    # POST /admin/users/:id/activate
    def activate
      @user.activate!
      redirect_to admin_users_path, notice: "#{@user.full_name} has been activated."
    end

    # POST /admin/users/:id/deactivate
    def deactivate
      @user.deactivate!
      redirect_to admin_users_path, notice: "#{@user.full_name} has been deactivated."
    end

    # POST /admin/users/:id/remove
    def remove
      @user.remove!
      redirect_to admin_users_path, notice: "#{@user.full_name} has been removed."
    end

    # POST /admin/users/:id/make_admin
    def make_admin
      @user.make_admin!
      redirect_to admin_users_path, notice: "#{@user.full_name} is now an admin."
    end

    # POST /admin/users/:id/make_member
    def make_member
      @user.make_member!
      redirect_to admin_users_path, notice: "#{@user.full_name} is now a member."
    end

    # POST /admin/users/:id/reset_password
    def reset_password
      @temporary_password = User.generate_temporary_password
      @user.update!(password: @temporary_password, password_changed: false)

      # TODO: Send email with new temporary password
      # UserMailer.password_reset(@user, @temporary_password).deliver_later

      render :password_reset
    end

    private

    def set_user
      @user = User.find(params[:id])
    end

    def user_params
      params.require(:user).permit(:first_name, :last_name, :email, :city, :role, :status)
    end
  end
end
