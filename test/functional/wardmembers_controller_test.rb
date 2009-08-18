require 'test_helper'

class WardmembersControllerTest < ActionController::TestCase
  def test_should_get_index
    get :index
    assert_response :success
    assert_not_nil assigns(:wardmembers)
  end

  def test_should_get_new
    get :new
    assert_response :success
  end

  def test_should_create_wardmembers
    assert_difference('Wardmembers.count') do
      post :create, :wardmembers => { }
    end

    assert_redirected_to wardmembers_path(assigns(:wardmembers))
  end

  def test_should_show_wardmembers
    get :show, :id => wardmembers(:one).id
    assert_response :success
  end

  def test_should_get_edit
    get :edit, :id => wardmembers(:one).id
    assert_response :success
  end

  def test_should_update_wardmembers
    put :update, :id => wardmembers(:one).id, :wardmembers => { }
    assert_redirected_to wardmembers_path(assigns(:wardmembers))
  end

  def test_should_destroy_wardmembers
    assert_difference('Wardmembers.count', -1) do
      delete :destroy, :id => wardmembers(:one).id
    end

    assert_redirected_to wardmembers_path
  end
end
