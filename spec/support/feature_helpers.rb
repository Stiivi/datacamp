module PageHelpers
  def create_index_page
    home_page
  end

  def home_page
    @__home_page ||= Page.find_by_page_name('index') || Factory(:page, page_name: 'index')
  end
end

module LoginHelpers
  def admin_user
    # CI may use multiple threads, and this could be a problem and some tests may fail, this avoid this problem
    @__admin_user ||= begin
      user = User.find_by_login('admin_user')
      if user
        user.password = 'secret'
        user
      else
        Factory(:user, login: 'admin_user', password: 'secret', api_access_level: Api::PREMIUM)
      end
    end
  end

  def login_as(user)
    visit new_session_path(locale: :en)
    fill_in "Username", with: user.login
    fill_in "Password", with: user.password
    click_button "Submit"
  end

  def generate_all_quality_status
    [
        'ok',
        'duplicate',
        'incomplete',
        'doubtful',
        'unclear',
        'absent'
    ].each { |name| QualityStatus.create!(name: name, image: name) }
  end

  def generate_sample_access_role_with_rights
    rights = [
        [:users, :manage_users],
        [:users, :block_users],
        [:users, :grant_rights],
        [:users, :set_api_access]
    ].map { |category, identifier| AccessRight.create!(identifier: identifier, category: category) }

    AccessRole.create!(identifier: :user_manager, access_rights: rights)
  end

  def generate_system_variables_sample
    [
        {:name => "theme",
         :description => "Theme",
         :value => "default"
        },
        {
            :name => "site_name",
            :description => "Site Name",
            :value => "Datacamp Site"
        },
    ].map{ |attributes| SystemVariable.create!(attributes) }
  end
end

module ExpectationHelpers
  def page_should_have_content_with(*names)
    Array.wrap(names).each do |name|
      page.should have_content name
    end
  end

  def page_should_not_have_content_with(*names)
    Array.wrap(names).each do |name|
      page.should_not have_content name
    end
  end
end

RSpec.configure do |config|
  config.include PageHelpers
  config.include LoginHelpers
  config.include ExpectationHelpers

  config.before(:each) do
    if RSpec.current_example.metadata[:type] == :feature
      create_index_page
    end
  end
end