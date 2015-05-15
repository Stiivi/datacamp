module PageHelpers
  def create_index_page
    home_page
  end

  def home_page
    @home_page ||= Page.find_by_page_name('index') || Factory(:page, page_name: 'index')
  end
end

module LoginHelpers
  def login_as(user)
    visit new_session_path(locale: :en)
    fill_in "Username", with: user.name
    fill_in "Password", with: user.password
    click_button "Submit"
  end
end

RSpec.configure do |config|
  config.include PageHelpers
  config.include LoginHelpers

  config.before(:each) do
    if RSpec.current_example.metadata[:type] == :feature
      create_index_page
    end
  end
end