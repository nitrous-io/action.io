module Support
  def sign_in
    visit '/users/sign_in'
    fill_in "Username", with: ENV['USERNAME']
    fill_in "Password", with: ENV['PASSWORD']
    click_on "Sign In"
  end

  def sign_out
    within '.header-nav' do
      find('a', text: ENV['USERNAME']).click
      find('a', text: 'Sign Out').click
    end
  end

  def wait_until(time=Capybara.default_wait_time)
    require 'timeout'
    Timeout::timeout time.to_i do
      sleep 0.1 until value = yield
      value
    end
  end

  def current_location_hash
    page.evaluate_script "window.location.hash"
  end

  def accept_confirm
    page.driver.browser.switch_to.alert.accept
  end

  # require to be on #/
  def create_box(name)
    click_on "New Box"
    fill_in "Name", with: name
    select "Southeast Asia (Singapore)", from: "Region"
    click_on "Create Box"
    page.should have_content("Provisioning")

    wait_until ENV['MAX_PROVISION_TIME'].to_i do
      current_location_hash.include? 'ide'
    end
  end

  # require to be on #/boxes
  def terminate_box(name)
    box_container = find("h3", text: box_name).first(:xpath, ".//..//..")
    box_container.click
    box_container.find(:xpath, './/button[contains(., "Shut Down")]').click
    wait_until { box_container.has_content? "Terminate" }
    box_container.find(:xpath, './/button[contains(., "Terminate")]').click
    wait_until { box_container.has_content? "Terminated" }
  end

  def type_in_console(str)
    console_frame = page.all("iframe").first do |frame|
      frame["src"].include? "terminal"
    end.native
    page.driver.switch_to.frame console_frame
    console = driver.switch_to.active_element
    console.send_keys str
  end

  def within_console
    frames = page.all("iframe")
    console_frame = frames[1]
    page.driver.browser.switch_to.frame console_frame.native
    console = page.driver.browser.switch_to.active_element
    console.click
    yield console
  end
end
