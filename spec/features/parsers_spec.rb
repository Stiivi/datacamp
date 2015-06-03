# coding: utf-8
require 'spec_helper'

describe 'Parsers' do
  let!(:donation_parser) { Factory(:donations_parser) }

  before(:each) do
    login_as(admin_user)
  end

  it 'user is able to see available parsers' do
    visit parsers_path(locale: :en)

    page.should have_content 'donations_parser'

    click_link 'Detail'
  end

  it 'user is able to run parser' do
    visit parsers_path(locale: :en)

    click_link 'Detail'

    expect_parser_will_be_called

    fill_in 'settings_year', with: '2013'
    click_button 'Spustiť'
  end

  private

  def expect_parser_will_be_called
    # there should be no mocking in high level test, but test without it would be super complicated
    parser = double(:parser)
    parser.should_receive(:perform)
    Parsers::DonationsParser::Downloader.should_receive(:new).with(donation_parser.id, 2013.to_i).and_return(parser)
  end

end