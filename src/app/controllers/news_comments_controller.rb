class NewsCommentsController < ApplicationController
  before_action :current_user
  before_action :load_news_comment,         only: %i[edit update remove destroy]
  before_action :check_news_comment_author, only: %i[edit update remove destroy]

  # GET /news/:news_item_id/comments/new
  def new
    @news_comment = NewsComment.new
    @news_comment.news_item_id = params[:news_item_id]
  end

  # GET /news/:news_item_id/comments/:id/edit
  def edit; end

  # POST /news/:news_item_id/comments
  def create
    @news_comment = NewsComment.new(news_comment_params)
    @news_comment.news_item_id = params[:news_item_id]
    @news_comment.message = root_src_img_tag(@news_comment.message)
    @news_comment.user_id = current_user.id

    if @news_comment.save
      flash[:notice] = t('flash.news.comment_created')
      redirect_to controller: 'news_items', action: 'show', id: @news_comment.news_item_id
    else
      @news_item = NewsItem.find(@news_comment.news_item_id)
      render action: "new"
    end
  end

  # PATCH /news/:news_item_id/comments/:id
  def update
    attrs = news_comment_params
    attrs[:message] = root_src_img_tag(attrs[:message]) if attrs[:message]
    if @news_comment.update(attrs)
      flash[:notice] = t('flash.news.comment_updated')
      redirect_to controller: 'news_items', action: 'show', id: @news_comment.news_item.id
    else
      render action: "edit"
    end
  end

  # GET /news/:news_item_id/comments/:id/remove
  def remove; end

  # DELETE /news/:news_item_id/comments/:id
  def destroy
    return redirect_to controller: 'news_items', action: 'show', id: @news_comment.news_item.id if params[:commit] == t('news_comments.remove.cancel')

    news_item_id = @news_comment.news_item.id
    @news_comment.destroy
    flash[:notice] = t('flash.news.comment_destroyed')
    redirect_to controller: 'news_items', action: 'show', id: news_item_id
  end

  private

  def news_comment_params
    params.expect(news_comment: [:message])
  end

  def load_news_comment
    @news_comment = NewsComment.find_by(id: params[:id])
    unless @news_comment
      flash[:error] = t('flash.news.comment_not_found')
      redirect_to controller: 'news_items', action: 'index'
    end
  end

  def check_news_comment_author
    user_is_author @news_comment
  end
end
