module PaginationHelper
  def page_navigation
    render 'shared/page_navigation', paginator: @paginator
  end
end
