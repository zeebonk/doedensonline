module RichTextHelper
  # The markup the TinyMCE toolbar produces, plus the images older posts embed.
  # TinyMCE underlines with <span style="text-decoration: underline;">.
  RICH_TEXT_TAGS = %w[p br strong b em i u s strike del span a ul ol li img].freeze
  RICH_TEXT_ATTRIBUTES = %w[href src alt title style].freeze

  # Renders HTML that users submitted through the TinyMCE editor. The editor
  # only runs in the browser, so the stored HTML can contain anything.
  def rich_text(html)
    sanitize(html, tags: RICH_TEXT_TAGS, attributes: RICH_TEXT_ATTRIBUTES)
  end
end
