module Paginatable
  extend ActiveSupport::Concern

  def paginate(scope, options)
    per_page = options.fetch(:per_page)
    page = params[:page_number] ? params[:page_number].to_i : 1
    total_pages = (scope.count.to_f / per_page).ceil
    @paginator = Paginator.new(page, total_pages)
    scope.latest(per_page, (page - 1) * per_page)
  end
end
