module ApplicationHelper
  def controller_stylesheet_link_tag
    name = controller.controller_name
    path = Rails.root.join('app', 'assets', 'stylesheets', "#{name}.css")
    stylesheet_link_tag(name) if path.exist?
  end
end
