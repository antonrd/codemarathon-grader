class UserInvite < ActiveRecord::Base
  validates :email,
            uniqueness: { message: "already exists in the user invites list",
                          case_sensitive: false }
end
