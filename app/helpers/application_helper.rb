module ApplicationHelper
  def full_controller_action_name
    class_name = "#{controller_path.gsub('/','_')} #{action_name}"
    class_name += ' fullscreen' if params[:fullscreen] == '1'
    class_name
  end

  def nav_li(name, path)
    content_tag :li, :class => (path == request.fullpath ? 'active' : nil) do
      link_to name, path
    end
  end

  def length_hiding_comment
    # NOTE: this breaks HTTP caching wherever it is used
    "<!--#{SecureRandom.hex(SecureRandom.random_number(1024) + 1)}-->".html_safe
  end
end
