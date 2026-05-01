class PhotoAlbumPicturesController < ApplicationController
  layout 'default'

  # GET /photo_album_pictures/1
  def show
    @photo_album = PhotoAlbum.find(params[:id])
    @photo_album_picture = PhotoAlbumPicture.new
    @photo_album_picture.photo_album_id = @photo_album.id
  end

  # POST /photo_album_pictures
  def create
    attrs = photo_album_picture_params
    @photo_album_picture = PhotoAlbumPicture.new(attrs)

    # Picture upload
    unless attrs[:filename].nil?
      begin
        picture = UploadPicture.new(attrs[:filename])
        create_images picture
        @photo_album_picture.filename = picture.filename
      rescue
        @photo_album_picture.errors.add(:filename, t('flash.photo_albums_errors.unsupported_image'))
      end
   end

    if @photo_album_picture.errors.empty? && @photo_album_picture.save
      redirect_to action: 'show', id: @photo_album_picture.photo_album_id
    else
      @photo_album = @photo_album_picture.photo_album
      render action: 'show', id: @photo_album_picture.photo_album_id
      end
  end

  # POST /photo_album_pictures/destory_many
  def destroy_many
    @photo_album = PhotoAlbum.find_by(id: params[:album])

    if params[:delete]
      for picture_id in params[:delete]
        picture = PhotoAlbumPicture.find(picture_id)
        remove_images picture.filename
        picture.destroy
      end
    end

    redirect_to action: 'show', id: @photo_album.id
  end

  private

  def photo_album_picture_params
    params.require(:photo_album_picture).permit(:filename, :photo_album_id)
  end
end
