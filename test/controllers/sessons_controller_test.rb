require 'test_helper'

class SessonsControllerTest < ActionDispatch::IntegrationTest
  test "should get new" do
    get sessons_new_url
    assert_response :success
  end

end
