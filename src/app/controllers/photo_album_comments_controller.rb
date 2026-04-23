class PhotoAlbumCommentsController < ApplicationController
  before_filter :load_photo_album_comment,         only: [:edit, :update, :remove, :destroy]
  before_filter :check_photo_album_comment_author, only: [:edit, :update, :remove, :destroy]

  # GET /photo_album_comments/new/1
  def new
    @photo_album_comment = PhotoAlbumComment.new

    if photo_album_from_id(params[:id])
      @photo_album_comment.photo_album_id = params[:id]
    else
      flash[:error] = t('flash.photo_album_comments.album_not_found')
      redirect_to controller: 'photo_albums'
    end
  end

  # GET /photo_album_comments/1/edit
  def edit
  end

  # POST /photo_album_comments
  def create
    @photo_album_comment = PhotoAlbumComment.new(params[:photo_album_comment])
    @photo_album_comment.message = root_src_img_tag(@photo_album_comment.message)
    @photo_album_comment.user_id = current_user.id

    if @photo_album_comment.save
      flash[:notice] = t('flash.photo_album_comments.created')
      redirect_to controller: 'photo_albums', action: 'show', id: @photo_album_comment.photo_album_id
    else
      flash[:error] = t('flash.photo_album_comments.message_required')
      render action: "new"
    end
  end

  # PUT /photo_album_comments/1
  def update
    params[:photo_album_comment][:message] = root_src_img_tag(params[:photo_album_comment][:message])
    if @photo_album_comment.update_attributes(params[:photo_album_comment])
      flash[:notice] = t('flash.photo_album_comments.updated')
      redirect_to controller: 'photo_albums', action: 'show', id: @photo_album_comment.photo_album.id
    else
      flash[:error] = t('flash.photo_album_comments.message_required')
      render action: "edit"
    end
  end

  # GET /photo_album_comments/remove/:id
  def remove
  end

  # DELETE /photo_album_comments/1
  def destroy
    return redirect_to controller: 'photo_albums', action: 'show', id: @photo_album_comment.photo_album_id if params[:commit] == t('photo_album_comments.remove.cancel')
    photo_album_id = @photo_album_comment.photo_album.id
    @photo_album_comment.destroy
    flash[:notice] = t('flash.photo_album_comments.destroyed')
    redirect_to controller: 'photo_albums', action: 'show', id: photo_album_id
  end

  private

  def photo_album_from_id(id)
    PhotoAlbum.find(id)
  rescue Exception => e
    nil
  end

  def load_photo_album_comment
    id = params[:id] || (params[:photo_album_comment] && params[:photo_album_comment][:id])
    @photo_album_comment = PhotoAlbumComment.find_by_id(id)
    unless @photo_album_comment
      flash[:error] = t('flash.photo_album_comments.comment_not_found')
      redirect_to controller: 'photo_albums', action: 'index'
    end
  end

  def check_photo_album_comment_author
    user_is_author @photo_album_comment
  end
end
