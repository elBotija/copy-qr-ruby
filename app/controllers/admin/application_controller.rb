module Admin
  class ApplicationController < ::ActionController::Base
    before_action :authenticate_admin!

    layout 'application'

    private

    def authenticate_admin!
      authenticate_user!

      redirect_to root_path unless current_user.admin?
    end
  end
end
