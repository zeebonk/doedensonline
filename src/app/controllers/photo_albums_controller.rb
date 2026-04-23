class PhotoAlbumsController < ApplicationController

  before_filter :load_photo_album,         :only => [:show, :edit, :remove, :manage_pictures, :update, :destroy, :add_picture, :destroy_many_pictures]
  before_filter :check_photo_album_author, :only => [:update, :destroy, :add_picture, :destroy_many_pictures]


  # GET /photo_albums
  def index
    @photo_albums = paginate_photo_albums
  end


  # GET /photo_albums/page/:page_number
  def page
    @photo_albums = paginate_photo_albums
    render :action => 'index'
  end


  # GET /photo_albums/1
  def show
    @current_user = current_user
    @photo_album_comments = PhotoAlbumComment.where("photo_album_id = ?", @photo_album.id).order('created_at ASC').all
  end


  # GET /photo_albums/new
  def new
    @photo_album = PhotoAlbum.new
  end


  # GET /photo_albums/1/edit
  def edit
  end


  # GET /photo_albums/1/remove
  def remove
  end


  # GET /photo_albums/1/manage_pictures
  def manage_pictures
  end


  # POST /photo_albums/add_picture
  def add_picture
    flash[:error] = nil
    flash[:notice] = t('flash.photo_albums.pictures_added')

    if !params['file']
      flash[:error] = t('flash.photo_albums.no_pictures_selected_upload')
      flash[:notice] = nil
    else
      for file in params['file']
        @photo_album_picture = PhotoAlbumPicture.new
        @photo_album_picture.photo_album_id = @photo_album.id

        begin
          picture = UploadPicture.new file
          create_images picture
          @photo_album_picture.filename  = picture.filename
          @photo_album_picture.save
        rescue
          @photo_album_picture.errors.add(:filename, t('flash.photo_albums_errors.unsupported_image'))
          @photo_album_picture.destroy
          remove_images picture.filename  if picture
          flash[:notice] = nil
          flash[:error] = t('flash.photo_albums.some_pictures_failed')
        end
      end
    end

    render :action => 'manage_pictures', :id => @photo_album.id
  end


  # POST /photo_albums/destroy_many_pictures
  def destroy_many_pictures
    if params[:selected]
      for picture_id in params[:selected]
        picture = PhotoAlbumPicture.find(picture_id)
        remove_images picture.filename
        picture.destroy
        flash[:notice] = t('flash.photo_albums.pictures_destroyed')
      end
    else
      flash[:error] = t('flash.photo_albums.no_pictures_selected_destroy')
    end

    render :action => 'manage_pictures', :id => @photo_album.id
  end


  # POST /photo_albums
  def create
    @photo_album = PhotoAlbum.new(params[:photo_album])
    @photo_album.user_id = current_user.id

    # Picture upload
    if params[:photo_album][:preview_picture] != nil
      begin
        @picture = UploadPicture.new params[:photo_album][:preview_picture]
        create_images @picture
        @photo_album.preview_picture = @picture.filename
      rescue
        @photo_album.errors.add(:preview_picture, t('flash.photo_albums_errors.unsupported_image'))
      end
		end

    if @photo_album.errors.empty? && @photo_album.save
      flash[:notice] = t('flash.photo_albums.created')
      redirect_to(@photo_album)
    else
      remove_images @photo_album.preview_picture

			@title_error = true if @photo_album.errors[:title]
			@description_error = true if @photo_album.errors[:description]
			@preview_picture_error = true if @photo_album.errors[:preview_picture]

      render :action => "new"
    end
  end


  # PUT /photo_albums/1
  def update
		if params["photo_album"]["preview_picture"] != nil
      begin
        @picture = UploadPicture.new params["photo_album"]["preview_picture"]
        create_images @picture
        remove_images @photo_album.preview_picture
        params["photo_album"]["preview_picture"] = @picture.filename
      rescue
        @photo_album.errors.add(:preview_picture, t('flash.photo_albums_errors.unsupported_image'))
      end
		end

    if @photo_album.errors.count == 0 && @photo_album.update_attributes(params[:photo_album])
      flash[:notice] = t('flash.photo_albums.updated')
      redirect_to(@photo_album)
    else
			@title_error = true if @photo_album.errors[:title]
			@description_error = true if @photo_album.errors[:description]
			@preview_picture_error = true if @photo_album.errors[:preview_picture]
      render :action => "edit"
    end
  end


  # DELETE /photo_albums/1
  def destroy
		return redirect_to :action => 'index' if params[:commit] == t('photo_albums.remove.cancel')
		remove_images @photo_album.preview_picture
		@photo_album.destroy
    flash[:notice] = t('flash.photo_albums.destroyed')
		redirect_to :action => 'index'
  end


private


  def load_photo_album
    id = params[:id] || params[:album_id]
    @photo_album = PhotoAlbum.find_by_id(id)
    unless @photo_album
      flash[:error] = t('flash.photo_albums.album_not_found')
      redirect_to :action => 'index'
    end
  end

  def check_photo_album_author
    user_is_author @photo_album
  end

  def paginate_photo_albums
    if params[:page_number]
      @page = params[:page_number].to_i
    else
      @page = 1
    end
    @news_per_page = 6
    @pages = (PhotoAlbum.all.count.to_f / @news_per_page).ceil
    offset = (@page - 1) * @news_per_page
    PhotoAlbum.latest(@news_per_page, offset)
  end


end
