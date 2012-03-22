module JasmineFixtureSaver
  # Saves the markup to a fixture file using the given name
  def save_fixture(markup, name)
    fixture_path = File.join(Rails.root, '/tmp/jasmine_fixtures')
    Dir.mkdir(fixture_path) unless File.exists?(fixture_path)
    fixture_file = File.join(fixture_path, "#{name}.html")
    File.open(fixture_file, 'w') do |file|
      file.puts(markup)
    end
  end

  def all_html
    response.body
  end

  # From the controller spec response body, extracts html identified
  # by the css selector.
  def html_for(selector = 'body')
    doc = Nokogiri::HTML(response.body)

    prepare_html(doc)

    content = doc.css(selector).first.to_s
    convert_body_tag_to_div(content)
  end

  def prepare_html(doc)
    copy_html_classnames_data_controller_and_data_action_to_body(doc)
    set_image_sources_to_nothing(doc)
    remove_third_party_scripts(doc)
    remove_iframes(doc)
  end

  def copy_html_classnames_data_controller_and_data_action_to_body(doc)
    html = doc.css('html').first
    body = doc.css('body').first
    return unless html && body
    classnames = html['class']
    body['class'] = [body['class'], classnames].compact.join(' ')
    #body['data-controller'] = html['data-controller']
    #body['data-action'] = html['data-action']
  end

  def set_image_sources_to_nothing(doc)
    blank_png = 'data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAAAQAAAADCAIAAAA7ljmRAAAAGElEQVQIW2P4DwcMDAxAfBvMAhEQMYgcACEHG8ELxtbPAAAAAElFTkSuQmCC'
    images = doc.css('img')
    images.each{ |img| img['src'] = blank_png }

    images = doc.css('[style*="background"]')
    images.each do |el|
      el['style'] = el['style'].gsub(/url\([^\)]*\)/,"url(#{blank_png})")
    end
  end

  def remove_third_party_scripts(doc)
    scripts = doc.css('#third_party_scripts') + doc.css('script[src]')
    scripts.remove if scripts
  end

  def remove_iframes(doc)
    iframes = doc.css('iframe')
    iframes.remove if iframes
  end

  def convert_body_tag_to_div(markup)
    markup.gsub("<body", '<div').gsub("</body>", "</div>")
  end
end

