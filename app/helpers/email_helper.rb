module EmailHelper
  def h1(text)
    content_tag(:h1, text, :class => "headline", :style => "font-weight: bold; font: 30px/30px \"Helvetica Neue\", Arial, Helvetica, sans-serif;")
  end

  def h2(text)
    content_tag(:h2, text, :style => "margin: 1em 0; font: 18px/22px 'Helvetica Neue', Arial, Helvetica, sans-serif; font-weight: bold; color: #222; background: #e0e0e0; padding: 10px 15px;")
  end

  def image(imgsrc, link=nil)
    out = '<p><center>'
    img = '<img src="'+imgsrc+'" height="380" width="550" style="border: 0;" class="image" />'
    out << link ? link_to(img, link, :style => "color: #2a4b79; text-decoration: none; -webkit-transition: color .2s ease;") : img
    out << "</center></p>"
    out.html_safe!
  end

  def email_link(text, link)
    link_to(text, link, :style => "color: #2a4b79; text-decoration: none; -webkit-transition: color .2s ease;")
  end
end
