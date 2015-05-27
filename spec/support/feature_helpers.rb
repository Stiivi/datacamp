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
        Factory(:user, login: 'admin_user', password: 'secret')
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