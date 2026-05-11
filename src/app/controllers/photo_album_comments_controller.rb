class PhotoAlbumCommentsController < ApplicationController
  before_action :load_photo_album_comment,         only: [:edit, :update, :remove, :destroy]
  before_action :check_photo_album_comment_author, only: [:edit, :update, :remove, :destroy]

  # GET /photo_albums/:photo_album_id/comments/new
  def new
    @photo_album_comment = PhotoAlbumComment.new

    if photo_album_from_id(params[:photo_album_id])
      @photo_album_comment.photo_album_id = params[:photo_album_id]
    else
      flash[:error] = t('flash.photo_album_comments.album_not_found')
      redirect_to photo_albums_path
    end
  end

  # GET /photo_albums/:photo_album_id/comments/:id/edit
  def edit
  end

  # POST /photo_albums/:photo_album_id/comments
  def create
    @photo_album_comment = PhotoAlbumComment.new(photo_album_comment_params)
    @photo_album_comment.photo_album_id = params[:photo_album_id]
    @photo_album_comment.message = root_src_img_tag(@photo_album_comment.message)
    @photo_album_comment.user_id = current_user.id

    if @photo_album_comment.save
      flash[:notice] = t('flash.photo_album_comments.created')
      redirect_to photo_album_path(@photo_album_comment.photo_album_id)
    else
      render action: "new"
    end
  end

  # PATCH /photo_albums/:photo_album_id/comments/:id
  def update
    attrs = photo_album_comment_params
    attrs[:message] = root_src_img_tag(attrs[:message]) if attrs[:message]
    if @photo_album_comment.update(attrs)
      flash[:notice] = t('flash.photo_album_comments.updated')
      redirect_to photo_album_path(@photo_album_comment.photo_album.id)
    else
      render action: "edit"
    end
  end

  # GET /photo_albums/:photo_album_id/comments/:id/remove
  def remove
  end

  # DELETE /photo_albums/:photo_album_id/comments/:id
  def destroy
    return redirect_to photo_album_path(@photo_album_comment.photo_album_id) if params[:commit] == t('photo_album_comments.remove.cancel')
    photo_album_id = @photo_album_comment.photo_album.id
    @photo_album_comment.destroy
    flash[:notice] = t('flash.photo_album_comments.destroyed')
    redirect_to photo_album_path(photo_album_id)
  end

  private

  def photo_album_comment_params
    params.require(:photo_album_comment).permit(:message)
  end

  def photo_album_from_id(id)
    PhotoAlbum.find(id)
  rescue Exception => e
    nil
  end

  def load_photo_album_comment
    @photo_album_comment = PhotoAlbumComment.find_by(id: params[:id])
    unless @photo_album_comment
      flash[:error] = t('flash.photo_album_comments.comment_not_found')
      redirect_to photo_albums_path
    end
  end

  def check_photo_album_comment_author
    user_is_author @photo_album_comment
  end
end
