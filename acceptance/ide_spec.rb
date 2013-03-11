require_relative './spec_helper'

describe 'IDE' do
  let(:box_name) { "fragrant-wind-#{Time.now.to_i}" }
  let(:browser) { page.driver.browser }

  before do
    sign_in
    visit "/app#/boxes/#{ENV['TEST_BOX_ID']}/ide"
    wait_until { !page.has_selector?('#ide_connecting') }
    page.evaluate_script "$(window).unbind(beforeunload:ide);"
  end

  describe 'console' do
    it 'accepts input and returns correct output' do
      within_console do |console|
        console.send_keys "echo $(( 3 + 4 ))\n"
        sleep 0.1 # sleep so we have time to get the results back
        console.attribute("innerText").should include("7")
      end
    end
  end

  #describe 'file tree' do
    #let(:sidebar) { page.find("#sidebar") }

    #it 'creates new file' do
    #end

    #it 'refreshes the tree' do
    #end
  #end

  #describe 'editor' do
    #let(:editor_view) { page.find('#ide_editor_view') }

    #it 'creates an untitled document' do
      #page.find('#ide_editor_view').first('.new_tab_button').click
      #binding.pry
    #end
#  end
end
