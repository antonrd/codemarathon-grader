require 'test_helper'

class UsersControllerTest < ActionController::TestCase
  test "should get reset_token" do
    get :reset_token
    assert_response :success
  end

end
