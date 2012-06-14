module RequestSpecHelpers
  def login_as_member(user = nil)
    user ||= create :user
    visit root_path
    fill_in 'user_username', :with => user.username
    fill_in 'user_password', :with => user.password
    click_button 'Sign in'
  end

  def set_cookie(key, val, domain='.example.com')
    cookies_array = cookies.instance_variable_get(:@cookies)
    cookies_array.reject! { |cookie| cookie.name == key }
    if val.present?
      cookies[key] = val
      cookies_array.select { |cookie| cookie.name == key }.each do |cookie|
        options = cookie.instance_variable_get(:@options)
        options['domain'] = domain
        options['path'] = '/'
        options['HttpOnly'] = nil
      end
    end
  end

  def assert_equal_secure_cookie(key, val, domain='.example.com')
    verifier.verify(cookies[key]).should == val
    cookie = cookies.send(:hash_for)[key]
    cookie.instance_variable_get(:@options).should have_key('HttpOnly')
    cookie.domain.should == domain
  end
end

