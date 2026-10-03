class NewsItemsController < ApplicationController
  before_action :current_user
  before_action :load_news_item,         only: %i[show edit update remove destroy]
  before_action :check_news_item_author, only: %i[edit update remove destroy]

  # GET /news
  def index
    @news_items = NewsItem.includes(:user, :news_comments)
                          .order(created_at: :desc)
                          .page(params[:page])
                          .per(10)
  end

  # GET /news/:id
  def show
    @news_comments = NewsComment.where(news_item_id: @news_item.id).order(:created_at).to_a
  end

  # GET /news/new
  def new
    @news_item = NewsItem.new
  end

  # GET /news/:id/edit
  def edit; end

  # POST /news
  def create
    @news_item = NewsItem.new(news_item_params)
    @news_item.message = root_src_img_tag(@news_item.message)
    @news_item.user_id = current_user.id

    if @news_item.save
      flash[:notice] = t('flash.news.created')
      targets = User.where(notify_news: true).where.not(id: current_user.id)
      targets.each do |target|
        Mailer.notify_new_news(target.email, @news_item, current_user).deliver_now
      end
      redirect_to action: 'index'
    else
      render action: "new"
    end
  end

  # PATCH /news/:id
  def update
    attrs = news_item_params
    attrs[:message] = root_src_img_tag(attrs[:message]) if attrs[:message]
    if @news_item.update(attrs)
      flash[:notice] = t('flash.news.updated')
      redirect_to action: "index"
    else
      render action: "edit"
    end
  end

  # GET /news/:id/remove
  def remove; end

  # DELETE /news/:id
  def destroy
    return redirect_to action: 'index' if params[:commit] == t('news_items.remove.cancel')

    @news_item.destroy
    flash[:notice] = t('flash.news.destroyed')
    redirect_to action: 'index'
  end

  private

  def news_item_params
    params.require(:news_item).permit(:message)
  end

  def load_news_item
    @news_item = NewsItem.find_by(id: params[:id])
    unless @news_item
      flash[:error] = t('flash.news.item_not_found')
      redirect_to action: 'index'
    end
  end

  def check_news_item_author
    user_is_author @news_item
  end
end
