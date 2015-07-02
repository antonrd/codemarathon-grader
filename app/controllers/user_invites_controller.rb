class UserInvitesController < ApplicationController
  def index
    @page_title = 'invites'
    @new_invite = UserInvite.new
    @items = []
    UserInvite.find_each do |user_invite|
      new_invite = OpenStruct.new(user_invite: user_invite, user_created_at: nil)
      matching_user = User.find_by(email: user_invite.email)
      new_invite.user_created_at = matching_user.created_at if matching_user.present?
      @items << new_invite
    end
  end

  def create
    user_invite = UserInvite.create(user_invite_params)

    if user_invite.valid?
      redirect_to user_invites_path, notice: "User invite added for #{params[:user_invite][:email]}"
    else
      redirect_to user_invites_path, alert: user_invite.errors.full_messages.join(" ")
    end
  end

  def destroy
    user_invite = UserInvite.find_by(id: params[:id])
    if user_invite
      user_invite.destroy
      redirect_to user_invites_path, notice: "User invite for #{user_invite.email} cancelled"
    else
      redirect_to user_invites_path, alert: "User invite for cancellation does not exist"
    end
  end

  protected

  def user_invite_params
    params.require(:user_invite).permit(:email)
  end
end
