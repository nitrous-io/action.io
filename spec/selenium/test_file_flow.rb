require 'rubygems'
require 'selenium-webdriver'

host = "https://dev.action.io:5000"
action_credentials = {:username => "lakshan@action.io", :password => "qaz123"}
box = { :id => 1, :name => "test-box" }

sourcelabs = {
	:id => "lakshan",
	:key => "06a5a4a9-9f10-49e5-b170-ff2de68f204b"
}

browser = { :name => :firefox, :version => "" }
platform = :MAC
use_local = true 

caps = Selenium::WebDriver::Remote::Capabilities.new
caps.browser_name = browser[:name]
caps.version = browser[:version] 
caps.platform = platform
caps[:name] = "Testing action.io local on Sauce"

# There are two ways to run the selenium tests 
# Either use locally installed driver
# or use source labs on demand server.
if use_local
	driver = Selenium::WebDriver.for browser[:name] 
else 
	driver = Selenium::WebDriver.for(
		:remote,
		:url => "http://#{sourcelabs[:id]}:#{sourcelabs[:key]}@ondemand.saucelabs.com:80/wd/hub",
		:desired_capabilities => caps)
end

driver.get "#{host}/users/sign_in"

# login
login = driver.find_element :id => "user_login"
login.send_keys action_credentials[:username] 

password = driver.find_element :id => "user_password"
password.send_keys action_credentials[:password]

form = driver.find_element :id => "new_user"
form.submit

driver.get "#{host}/app#/boxes/#{box[:id]}/ide"
console_frame = driver.find_elements(:tag_name, "iframe")[1]
driver.switch_to.frame console_frame
console = driver.switch_to.active_element

# wait till console is ready
wait = Selenium::WebDriver::Wait.new(:timeout => 60)
wait.until {  driver.find_elements(:css, "div.terminal div").one? { |div| div.text.gsub(/\s+/, "") == "action@#{box[:name]}:~$" } }

console.send_keys("touch test\n")

# switch the focus back to main frame
driver.switch_to.default_content

# refresh the tree
driver.find_element(:css, "button[title$='Refresh Tree']").click
tree_root = driver.find_element(:css, "div.tree li:first-child")
wait.until { driver.find_element(:css, "div.tree li:first-child ul li") }

# select the created file
driver.find_element(:css, "div.tree li:first-child ul li a").click

# enter some text
wait.until { driver.find_element(:class, "CodeMirror") }
code_editor = driver.switch_to.active_element
code_editor.send_keys("test input")

# save the file
code_editor.send_keys([:meta, "s"])

# wait till the file is saved
wait.until { driver.find_elements(:class, "icon-asterik").length == 0 }

# remove the file 
driver.mouse.context_click driver.find_element(:css, "div.tree li:first-child ul li a")
wait.until { driver.find_element(:css, "#ide_path_context_menu_view .dropdown-menu") }

delete_file_option = driver.find_element(:css, "#ide_sidebar_view .dropdown-menu li:last-of-type a")
delete_file_option.click

prompt = driver.switch_to.alert
prompt.accept

driver.quit
