# -*- encoding : utf-8 -*-
require 'test_helper'

class DatasetDescriptionTest < ActiveSupport::TestCase
  test "should create slug from title" do
    users = DatasetDescription.create :database => 'main',
                          :identifier => 'users',
                          :category => 'blog',
                          :title => 'The Users',
                          :description => 'these are users'
    
    assert users.valid?, "couldn't create entity"
    
    assert_equal users.slug, 'the-users', "slug wasn't generated properly"
  end
  
  test "should not allow two entities with same slug" do
    entity1 = DatasetDescription.create :title => 'Test Slug'
    
    entity2 = DatasetDescription.create :title => 'Test Slug'
    
    assert_not_equal entity1.slug, entity2.slug
  end
  
  test "should append '-n' if there already is such a slug" do
    entity1 = DatasetDescription.create :title => 'Test Slug'
    assert_equal 'test-slug', entity1.slug
    
    entity2 = DatasetDescription.create :title => 'Test Slug'
    assert_equal 'test-slug-1', entity2.slug
    
    entity3 = DatasetDescription.create :title => 'Test Slug'
    assert_equal 'test-slug-2', entity3.slug
  end
end
