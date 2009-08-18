require 'test_helper'

class StakesControllerTest < ActionController::TestCase
  def test_should_get_index
    get :index
    assert_response :success
    assert_not_nil assigns(:stakes)
  end

  def test_should_get_new
    get :new
    assert_response :success
  end

  def test_should_create_stake
    assert_difference('Stake.count') do
      post :create, :stake => { }
    end

    assert_redirected_to stake_path(assigns(:stake))
  end

  def test_should_show_stake
    get :show, :id => stakes(:one).id
    assert_response :success
  end

  def test_should_get_edit
    get :edit, :id => stakes(:one).id
    assert_response :success
  end

  def test_should_update_stake
    put :update, :id => stakes(:one).id, :stake => { }
    assert_redirected_to stake_path(assigns(:stake))
  end

  def test_should_destroy_stake
    assert_difference('Stake.count', -1) do
      delete :destroy, :id => stakes(:one).id
    end

    assert_redirected_to stakes_path
  end
end
