class ApplicationController < ActionController::Base
  before_action :authenticate_user!, unless: :api_payment_request?
  before_action :allow_only_user!, unless: :api_payment_request?
  

  def after_sign_in_path_for(resource)
    if resource.is_a?(User) && resource.admin?
      admin_root_path
    else
      stored_location_for(resource) || super
    end
  end

  def after_sign_out_path_for(resource_or_scope)
    new_user_session_path
  end

  private

  def allow_only_user!
    redirect_to admin_root_path if !devise_controller? && current_user.admin?
  end
  
  # Método para determinar si la solicitud es a los endpoints de pago de la API
  def api_payment_request?
    request.path.start_with?('/api/v1/webhook', '/api/v1/create-preference', '/api/v1/orders/')
  end
end