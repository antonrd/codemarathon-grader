class RegistrationsController < Devise::RegistrationsController
  before_filter :user_invited?, only: [:create]

  def user_invited?
    unless UserInvite.find_by(email: params[:user][:email]).present?
      flash[:error] = "The email #{params[:user][:email]} is not invited yet."
      redirect_to new_user_registration_path
    end
  end
end
