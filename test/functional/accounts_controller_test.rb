# -*- encoding : utf-8 -*-
require 'test_helper'

class AccountsControllerTest < ActionController::TestCase
  # Replace this with your real tests.
  test "open forgot password page" do
    get :forgot
  end
  
  test "post forgot password form" do
    assert_difference 'ActionMailer::Base.deliveries.size', +1 do
      post :forgot, :user => {:email => "vojto@rinik.net"}
    end
  end
end
