# frozen_string_literal: true

module Admin
  # ThemesController handles admin theme management
  #
  class ThemesController < BaseController
    # GET /admin/themes
    def index
      @themes = [] # TODO: Theme.all
    end

    # GET /admin/themes/:id
    def show
    end

    # GET /admin/themes/new
    def new
    end

    # POST /admin/themes
    def create
    end

    # GET /admin/themes/:id/edit
    def edit
    end

    # PATCH /admin/themes/:id
    def update
    end

    # DELETE /admin/themes/:id
    def destroy
    end
  end
end
