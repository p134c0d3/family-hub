# frozen_string_literal: true

module Admin
  # ThemesController handles admin theme management
  #
  class ThemesController < BaseController
    before_action :set_theme, only: [:show, :edit, :update, :destroy, :set_default, :preview]

    # GET /admin/themes
    def index
      @themes = Theme.order(:name)
    end

    # GET /admin/themes/:id
    def show
    end

    # GET /admin/themes/new
    def new
      @theme = Theme.new(colors: Theme.default_colors)
    end

    # POST /admin/themes
    def create
      @theme = Theme.new(theme_params)
      @theme.created_by = current_user

      if @theme.save
        redirect_to admin_themes_path, notice: "Theme created successfully."
      else
        render :new, status: :unprocessable_entity
      end
    end

    # GET /admin/themes/:id/edit
    def edit
    end

    # PATCH /admin/themes/:id
    def update
      if @theme.update(theme_params)
        redirect_to admin_themes_path, notice: "Theme updated successfully."
      else
        render :edit, status: :unprocessable_entity
      end
    end

    # DELETE /admin/themes/:id
    def destroy
      if @theme.users.any?
        redirect_to admin_themes_path, alert: "Cannot delete theme that is currently in use by #{@theme.users.count} user(s)."
      else
        @theme.destroy
        redirect_to admin_themes_path, notice: "Theme deleted successfully."
      end
    end

    # POST /admin/themes/:id/set_default
    def set_default
      @theme.update(is_default: true)
      redirect_to admin_themes_path, notice: "#{@theme.name} is now the default theme."
    end

    # GET /admin/themes/:id/preview
    def preview
      respond_to do |format|
        format.json { render json: { css: @theme.to_css_variables } }
        format.html
      end
    end

    private

    def set_theme
      @theme = Theme.find(params[:id])
    end

    def theme_params
      params.require(:theme).permit(:name, :description, :is_active, colors: {})
    end
  end
end
