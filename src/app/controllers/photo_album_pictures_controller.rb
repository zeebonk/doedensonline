class PhotoAlbumPicturesController < ApplicationController
  layout 'default'

  before_action :load_photo_album
  before_action :check_photo_album_author, only: [:create, :destroy_many]

  # GET /photo_albums/:photo_album_id/pictures
  def index
  end

  # POST /photo_albums/:photo_album_id/pictures
  def create
    files = Array(params['file']).reject(&:blank?)

    if files.empty?
      flash[:error] = t('flash.photo_albums.no_pictures_selected_upload')
      return render action: 'index'
    end

    written_filenames = []
    begin
      PhotoAlbumPicture.transaction do
        files.each do |file|
          picture = UploadPicture.new(file)
          create_images picture
          written_filenames << picture.filename
          PhotoAlbumPicture.create!(
            photo_album_id: @photo_album.id,
            filename: picture.filename
          )
        end
      end
      flash[:notice] = t('flash.photo_albums.pictures_added')
    rescue UploadPicture::InvalidUpload, ActiveRecord::ActiveRecordError, StandardError
      written_filenames.each { |fn| remove_images fn }
      flash[:error] = t('flash.photo_albums.some_pictures_failed')
    end

    render action: 'index'
  end

  # POST /photo_albums/:photo_album_id/pictures/destroy_many
  def destroy_many
    if params[:selected]
      params[:selected].each do |picture_id|
        picture = PhotoAlbumPicture.find(picture_id)
        remove_images picture.filename
        picture.destroy
      end
      flash[:notice] = t('flash.photo_albums.pictures_destroyed')
    else
      flash[:error] = t('flash.photo_albums.no_pictures_selected_destroy')
    end

    render action: 'index'
  end

  private

  def load_photo_album
    @photo_album = PhotoAlbum.find_by(id: params[:photo_album_id])
    unless @photo_album
      flash[:error] = t('flash.photo_albums.album_not_found')
      redirect_to photo_albums_path
    end
  end

  def check_photo_album_author
    user_is_author @photo_album
  end
end
