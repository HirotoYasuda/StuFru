require 'test_helper'

class MicropostsControllerTest < ActionDispatch::IntegrationTest
  test "should get create" do
    get microposts_create_url
    assert_response :success
  end

  test "should get show" do
    get microposts_show_url
    assert_response :success
  end

  test "should get edit" do
    get microposts_edit_url
    assert_response :success
  end

  test "should get update" do
    get microposts_update_url
    assert_response :success
  end

  test "should get destroy" do
    get microposts_destroy_url
    assert_response :success
  end

end
