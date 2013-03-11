require_relative './spec_helper'

describe 'Box' do
  let(:box_name) { "fragrant-wind-#{Time.now.to_i}" }

  before do
    sign_in
    visit '/app'
  end

  it 'creates and terminates a box' do
    create_box box_name
    click_on 'Boxes'
    terminate_box box_name
  end

  it 'cancels without creating a box' do
    click_on "New Box"
    click_on "Cancel"
    page.should_not have_content(box_name)
  end
end
