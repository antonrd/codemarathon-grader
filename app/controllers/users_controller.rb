class UsersController < ApplicationController
  before_filter :authenticate_user!

  def reset_token
    current_user.api_key.destroy if !current_user.api_key.nil?
    new_api_key = current_user.create_api_key
    redirect_to edit_user_registration_path
  end
end
