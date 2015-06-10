class ApplicationController < ActionController::Base
  before_filter :store_location
  before_action :configure_permitted_parameters, if: :devise_controller?

  protect_from_forgery

  protected

  def configure_permitted_parameters
    devise_parameter_sanitizer.for(:account_update) << :file_path
  end

  def restrict_access
    authenticate_or_request_with_http_token do |token, options|
      api_key = ApiKey.where(access_token: token).first
      api_key && api_key.user && api_key.user.email == params["email"]
    end
  end

  def store_location
    # store last url - this is needed for post-login redirect to whatever the user last visited.
    return unless request.get?
    if (request.path != "/users/sign_in" &&
        request.path != "/users/sign_up" &&
        request.path != "/users/password/new" &&
        request.path != "/users/password/edit" &&
        request.path != "/users/confirmation" &&
        request.path != "/users/confirmation/new" &&
        request.path != "/users/sign_out" &&
        !request.xhr?) # don't store ajax calls
      session[:previous_url] = request.fullpath
      Rails.logger.info "Setting #{request.fullpath}"
    end
  end

  def after_sign_in_path_for(resource)
    session[:previous_url] || root_path
  end

  def after_sign_out_path_for(resource)
    new_user_session_path
  end
end
