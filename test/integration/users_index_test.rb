require 'test_helper'

class UsersIndexTest < ActionDispatch::IntegrationTest
  def setup
    @admin     = users(:michael)
    @non_admin = users(:archer)
  end

  test "index as admin including pagination and delete links" do
    log_in_as(@admin)
    get users_path
    assert_template 'users/index'
    assert_select 'div.pagination'
    first_page_of_users = User.paginate(page: 1)
    first_page_of_users.each do |user|
      assert_select 'a[href=?]', user_path(user), text: user.name
      unless user == @admin
        assert_select 'a[href=?]', user_path(user), text: 'delete'
      end
    end
    assert_difference 'User.count', -1 do
      delete user_path(@non_admin)
    end
  end

  test "index as non-admin" do
    log_in_as(@non_admin)
    get users_path
    assert_select 'a', text: 'delete', count: 0
  end
  
  test "checking for presence of non-activated users" do
    get signup_path
    assert_difference 'User.count', 1 do
      post users_path, user: { name:  "I SHOULD NOT APPEAR",
                               email: "ishouldnotappear@example.com",
                               password:              "password",
                               password_confirmation: "password" }
    end
    user = assigns(:user)
    assert_not user.activated?
    log_in_as(@non_admin)
    get users_path
    present_users = User.paginate(page: 1)
      (1..present_users.total_pages).each do |page|
        page_of_users = User.paginate(page: page)
        page_of_users.each do |test_user|
          if user.name == test_user.name 
            assert_select 'a[href=?]', user_path(user), {count: 0, 
                                                         text: user.name}
          end
        end
      end
  end
  
end
