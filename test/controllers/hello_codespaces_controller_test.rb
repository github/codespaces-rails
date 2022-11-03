require "test_helper"

class HelloCodespacesControllerTest < ActionDispatch::IntegrationTest
  test "should get index" do
    get hello_codespaces_index_url
    assert_response :success
  end
end
