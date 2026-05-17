class Paginator
  WINDOW = 2
  GAP = :gap

  attr_reader :current_page, :total_pages

  def initialize(current_page, total_pages)
    @current_page = current_page
    @total_pages = total_pages
  end

  def entries
    return [] if total_pages < 1

    window = ((current_page - WINDOW)..(current_page + WINDOW)).to_a
    pages = ([1, *window, total_pages] & (1..total_pages).to_a).uniq.sort

    result = []
    pages.each_with_index do |page, i|
      result << GAP if i.positive? && page - pages[i - 1] > 1
      result << page
    end
    result
  end

  def first_page?
    current_page == 1
  end

  def last_page?
    current_page == total_pages
  end

  def prev_page
    current_page - 1
  end

  def next_page
    current_page + 1
  end
end
