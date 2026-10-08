class PhotoAlbumsController < ApplicationController
  before_action :load_photo_album,         only: %i[show edit remove update destroy]
  before_action :check_photo_album_author, only: %i[update destroy]

  # GET /photo_albums
  def index
    @photo_albums = PhotoAlbum.includes(:photo_album_pictures)
                              .order(created_at: :desc)
                              .page(params[:page])
                              .per(6)
  end

  # GET /photo_albums/1
  def show
    @current_user = current_user
    @photo_album_comments = PhotoAlbumComment.where(photo_album_id: @photo_album.id).order(:created_at).to_a
  end

  # GET /photo_albums/new
  def new
    @photo_album = PhotoAlbum.new
  end

  # GET /photo_albums/1/edit
  def edit; end

  # GET /photo_albums/1/remove
  def remove; end

  # POST /photo_albums
  def create
    album_params = params[:photo_album] || {}
    @photo_album = PhotoAlbum.new(title: album_params[:title], description: album_params[:description])
    @photo_album.user_id = current_user.id

    files = Array(album_params[:pictures]).compact_blank

    @photo_album.valid?
    @photo_album.errors.add(:pictures, t('flash.photo_albums_errors.no_pictures_selected')) if files.empty?

    success = false
    written_filenames = []

    if @photo_album.errors.empty?
      PhotoAlbum.transaction do
        @photo_album.save!
        files.each do |file|
          picture = UploadPicture.new(file)
          create_images picture
          written_filenames << picture.filename
          PhotoAlbumPicture.create!(
            photo_album_id: @photo_album.id,
            filename: picture.filename
          )
        end
        success = true
      rescue UploadPicture::InvalidUpload
        @photo_album.errors.add(:pictures, t('flash.photo_albums_errors.unsupported_image'))
        raise ActiveRecord::Rollback
      rescue ActiveRecord::ActiveRecordError
        raise ActiveRecord::Rollback
      end
      written_filenames.each { |fn| remove_images fn } unless success
    end

    if success
      flash[:notice] = t('flash.photo_albums.created')
      targets = User.where(notify_photo_album: true).where.not(id: current_user.id)
      targets.each do |target|
        Mailer.notify_new_photo_album(target.email, @photo_album, current_user).deliver_now
      end
      redirect_to(@photo_album)
    else
      render action: "new"
    end
  end

  # PUT /photo_albums/1
  def update
    if @photo_album.update(photo_album_params)
      flash[:notice] = t('flash.photo_albums.updated')
      redirect_to(@photo_album)
    else
      render action: "edit"
    end
  end

  # DELETE /photo_albums/1
  def destroy
    return redirect_to action: 'index' if params[:commit] == t('photo_albums.remove.cancel')

    @photo_album.destroy
    flash[:notice] = t('flash.photo_albums.destroyed')
    redirect_to action: 'index'
  end

  private

  def photo_album_params
    params.expect(photo_album: %i[title description])
  end

  def load_photo_album
    @photo_album = PhotoAlbum.find_by(id: params[:id])
    unless @photo_album
      flash[:error] = t('flash.photo_albums.album_not_found')
      redirect_to action: 'index'
    end
  end

  def check_photo_album_author
    user_is_author @photo_album
  end
end
