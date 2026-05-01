class NewsController < ApplicationController
  include Paginatable

  before_filter :current_user
  before_filter :load_news_item,            only: [:edit, :update, :remove, :destroy]
  before_filter :check_news_item_author,    only: [:edit, :update, :remove, :destroy]
  before_filter :load_news_comment,         only: [:edit_comment, :update_comment, :remove_comment, :destroy_comment]
  before_filter :check_news_comment_author, only: [:edit_comment, :update_comment, :remove_comment, :destroy_comment]

  # GET /news/
  def index
    @news_items = paginate(NewsItem, per_page: 10)
  end

  # GET /news/page/:page_number
  def page
    @news_items = paginate(NewsItem, per_page: 10)
    render action: 'index'
  end

  # GET /news/add
  def add
    @news_item = NewsItem.new
  end

  # POST /news/create
  def create
    @news_item = NewsItem.new(params[:news_item])
    @news_item.message = root_src_img_tag(@news_item.message)
    @news_item.user_id = current_user.id

    if @news_item.save
      flash[:notice] = t('flash.news.created')
      targets = User.where(notify_news: true).where('id != ?', current_user.id)
      targets.each do |target|
        Mailer.notify_new_news(target.email, @news_item, current_user).deliver
      end
      redirect_to action: 'index'
    else
      render action: "add"
    end
  end

  # GET /news/edit
  def edit
  end

  # PUT /news/update
  def update
    params[:news_item][:message] = root_src_img_tag(params[:news_item][:message])
    if @news_item.update_attributes(params[:news_item])
      flash[:notice] = t('flash.news.updated')
      redirect_to action: "index"
    else
      render action: "edit"
    end
  end

  # GET /news/remove/:id
  def remove
  end

  # POST /news/destroy
  def destroy
    return redirect_to action: 'index' if params[:commit] == t('news.remove.cancel')
    for news_comment in @news_item.news_comments
      news_comment.destroy
    end
    @news_item.destroy
    flash[:notice] = t('flash.news.destroyed')
    redirect_to action: 'index'
  end

  # GET /news/view/:id
  def view
    @news_item = news_item_by_id params[:id]
    if !@news_item
      flash[:error] = t('flash.news.item_not_found')
      redirect_to action: 'index'
    else
      @news_comments = NewsComment.where("news_item_id = ?", @news_item.id).order('created_at ASC').all
    end
  end

  # GET /news/add_comment
  def add_comment
    @news_comment = NewsComment.new
    @news_comment.news_item_id = params[:id]
  end

  # POST /news/create_comment
  def create_comment
    @news_comment = NewsComment.new(params[:news_comment])
    @news_comment.message = root_src_img_tag(@news_comment.message)
    @news_comment.user_id = current_user.id

    if @news_comment.save
      flash[:notice] = t('flash.news.comment_created')
      redirect_to action: 'view', id: @news_comment.news_item_id
    else
      @news_item = NewsItem.find(@news_comment.news_item_id)
      render action: "add_comment"
    end
  end

  # GET /news/edit_comment/:id
  def edit_comment
  end

  # PUT /news/update_comment
  def update_comment
    params[:news_comment][:message] = root_src_img_tag(params[:news_comment][:message])
    if @news_comment.update_attributes(params[:news_comment])
      flash[:notice] = t('flash.news.comment_updated')
      redirect_to action: 'view', id: @news_comment.news_item.id
    else
      render action: "edit_comment"
    end
  end

  # GET /news/remove_comment/:id
  def remove_comment
  end

  # POST /news/destroy_comment
  def destroy_comment
    return redirect_to action: 'view', id: @news_comment.news_item.id if params[:commit] == t('news.remove_comment.cancel')
    news_item_id = @news_comment.news_item.id
    @news_comment.destroy
    flash[:notice] = t('flash.news.comment_destroyed')
    redirect_to action: 'view', id: news_item_id
  end

  private

  def load_news_item
    id = params[:id] || (params[:news_item] && params[:news_item][:id])
    @news_item = NewsItem.find_by_id(id)
    unless @news_item
      flash[:error] = t('flash.news.item_not_found')
      redirect_to action: 'index'
    end
  end

  def check_news_item_author
    user_is_author @news_item
  end

  def load_news_comment
    id = params[:id] || (params[:news_comment] && params[:news_comment][:id])
    @news_comment = NewsComment.find_by_id(id)
    unless @news_comment
      flash[:error] = t('flash.news.comment_not_found')
      redirect_to action: 'index'
    end
  end

  def check_news_comment_author
    user_is_author @news_comment
  end

  def news_item_by_id(id)
    NewsItem.find(id)
  rescue Exception => e
    nil
  end
end
