module ApplicationHelper
  def controller_stylesheet_link_tag
    name = controller.controller_name
    path = File.join(Rails.public_path, 'stylesheets', "#{name}.css")
    stylesheet_link_tag(name) if File.exist?(path)
  end
end
