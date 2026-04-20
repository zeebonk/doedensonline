module ApplicationHelper
  def controller_stylesheet_link_tag
    name = controller.controller_name
    path = File.join(Rails.public_path, 'stylesheets', "#{name}.css")
    stylesheet_link_tag(name) if File.exist?(path)
  end

  # Drop-in replacement for the Rails 2 `f.error_messages` / `error_messages_for`
  # helper, which was extracted to the `dynamic_form` plugin in Rails 3.
  def error_messages_for_record(record)
    return '' if record.nil? || record.errors.empty?

    items = record.errors.full_messages.map { |msg| content_tag(:li, msg) }
    content_tag(:div, :class => 'errorExplanation') do
      content_tag(:h2, "#{pluralize(record.errors.count, 'error')} prohibited this from being saved") +
        content_tag(:ul, items.join.html_safe)
    end
  end
end
