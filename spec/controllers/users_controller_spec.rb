# -*- encoding : utf-8 -*-
# Hello kids!
# Just wanted to say that this test is messy by intention.
# Especially to logging in part. It's the first spec for this
# project (:o), so when I add more, I'll move that logic some-
# where else, but for now - it's OK.

require 'spec_helper'

describe UsersController do

#   before :all do
#     User.delete_all # Truncation didn't work for me, so quick fix here
#     @auth_user = User.new(:login => "admin", :email => "admin@admin.com", 
#                           :password => "admin", :is_super_user => true, 
#                           :name => "Admin")
#     @auth_user.save(false)
#   end
# 
#   describe '#index' do
#     it "renders csv out of users" do
#       controller.session[:user_id] = @auth_user.id # This is the messy part
#       user = User.new(:login => "test", :email => "test@test.com", :name => "Test")
#       user.save(false)
#       
#       request.env["HTTP_ACCEPT"] = "text/csv"
#       get :index
#       response.body.should == "login,name,email
# admin,Admin,admin@admin.com
# test,Test,test@test.com"
#     end
#   end

end
