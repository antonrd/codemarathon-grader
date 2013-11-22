class ApplicationController < ActionController::Base
  protect_from_forgery

protected
  def restrict_access
    authenticate_or_request_with_http_token do |token, options|
      api_key = ApiKey.where(access_token: token).first
      api_key && api_key.user && api_key.user.email == params["email"]
    end
  end
end
