require 'test_helper'

class MembersControllerTest < ActionController::TestCase
  def test_should_get_index
    get :index
    assert_response :success
    assert_not_nil assigns(:members)
  end

  def test_should_get_new
    get :new
    assert_response :success
  end

  def test_should_create_member
    assert_difference('Member.count') do
      post :create, :member => { }
    end

    assert_redirected_to member_path(assigns(:member))
  end

  def test_should_show_member
    get :show, :id => members(:one).id
    assert_response :success
  end

  def test_should_get_edit
    get :edit, :id => members(:one).id
    assert_response :success
  end

  def test_should_update_member
    put :update, :id => members(:one).id, :member => { }
    assert_redirected_to member_path(assigns(:member))
  end

  def test_should_destroy_member
    assert_difference('Member.count', -1) do
      delete :destroy, :id => members(:one).id
    end

    assert_redirected_to members_path
  end
end
