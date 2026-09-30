module ApplicationHelper
  def error_messages_for(record)
    return if record.errors.empty?

    content_tag(:div, id: 'errorExplanation') do
      safe_join([
                  content_tag(:h2, t('activerecord.errors.template.header')),
                  content_tag(:p, t('activerecord.errors.template.body')),
                  content_tag(:ul, safe_join(record.errors.full_messages.map { |message| content_tag(:li, message) }))
                ])
    end
  end
end
