class PhotoAlbumsController < ApplicationController

	
  # GET /photo_albums
  def index	
  	@page_title = ["Fotoalbums overzicht", "Fotoalbums"]
    @photo_albums = paginate_photo_albums
  end

	
  # GET /news/page/:page_number
  def page
    @page_title = ["Fotoalbums overzicht", "Fotoalbums"]
    @photo_albums = paginate_photo_albums
    render :action => 'index'
  end

	
  # GET /photo_albums/1
  def show
    @current_user = current_user;
  	@page_title = ["Fotoalbum bekijken", "Fotoalbums"]
    @photo_album = PhotoAlbum.find(params[:id])
		@photo_album_comments = PhotoAlbumComment.find :all, :conditions => ["photo_album_id = ?", @photo_album.id], :order => 'created_at ASC'
  end

	
  # GET /photo_albums/new
  def new
  	@page_title = ["Fotoalbum aanmaken", "Fotoalbums"]
    @photo_album = PhotoAlbum.new
  end

	
  # GET /photo_albums/1/edit
  def edit
  	@page_title = ["Fotoalbum aanpassen", "Fotoalbums"]
    @photo_album = PhotoAlbum.find(params[:id])
  end

	# GET /photo_albums/1/remove
	def remove
  	@page_title = ["Fotoalbum verwijderen", "Fotoalbums"]
    @photo_album = PhotoAlbum.find(params[:id])
  end
	
  
  # GET /photo_albums/1/manage_pictures
  def manage_pictures
  	@page_title = ["Foto's beheren", "Fotoalbums"]
  	@photo_album = PhotoAlbum.find(params[:id])
  end

  
  # POST /photo_albums/add_picture
  def add_picture
  	flash[:error] = nil
  	flash[:notice] = "Alle foto's zijn succesvol toegevoegd."
  	
  	@photo_album = PhotoAlbum.find_by_id params[:album_id].to_i
  	validate_author @photo_album
  	
  	if !params['file']
      flash[:error] = "U heeft geen foto's geselecteerd om toe te voegen."   	 
      flash[:notice] = nil
	else  	
  	  for file  in params['file']
  	  	
        @photo_album_picture = PhotoAlbumPicture.new
        @photo_album_picture.photo_album_id = @photo_album.id
        
        begin
          picture = UploadPicture.new file
          create_images picture
          @photo_album_picture.filename  = picture.filename
          @photo_album_picture.save
        rescue
          @photo_album_picture.errors.add(:filename, "Unsupported image selected")
          @photo_album_picture.destroy
          remove_images picture.filename  if picture
          flash[:notice] = nil
          flash[:error] = "Niet alle foto's konden worden toegevoegd."   	 
        end
      
      end 
    end
  	
    @page_title = ["Foto's beheren", "Fotoalbums"]
    render :action => 'manage_pictures', :id => @photo_album.id
  end
  
  
  # POST /photo_albums/destory_many_pictures
  def destroy_many_pictures
 		
  	@photo_album = PhotoAlbum.find_by_id params[:album_id]
  	
  	validate_author @photo_album
  	
    if params[:selected]
	  for picture_id in params[:selected]
	    picture = PhotoAlbumPicture.find(picture_id)
	    remove_images picture.filename
        picture.destroy
        flash[:notice] = "Geselecteerde foto(s) succesvol verwijderd."
	  end		
    else
      flash[:error] = "Geen foto's geselecteerd om te verwijderen."
    end
	
    @page_title = ["Foto's beheren", "Fotoalbums"]
  	@photo_album = PhotoAlbum.find(params['album_id'].to_i)
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
        @photo_album.errors.add(:preview_picture, "Unsupported image selected")
      end
		end
    
    if @photo_album.errors.empty? && @photo_album.save
      flash[:notice] = 'Fotoalbum is succesvol toegevoegd.'
      redirect_to(@photo_album)
    else
      @page_title = ["Fotoalbum aanmaken", "Fotoalbums"]
      remove_images @photo_album.preview_picture
			
			@title_error = true if @photo_album.errors[:title]
			@description_error = true if @photo_album.errors[:description]
			@preview_picture_error = true if @photo_album.errors[:preview_picture]
			
      render :action => "new"
    end
  end


  # PUT /photo_albums/1
  def update
    @photo_album = PhotoAlbum.find(params[:id])
		validate_author @photo_album
	
		if params["photo_album"]["preview_picture"] != nil
      begin
        @picture = UploadPicture.new params["photo_album"]["preview_picture"]
        create_images @picture
        remove_images @photo_album.preview_picture
        params["photo_album"]["preview_picture"] = @picture.filename
      rescue
        @photo_album.errors.add(:preview_picture, "Unsupported image selected")
      end
		end

    if @photo_album.errors.count == 0 && @photo_album.update_attributes(params[:photo_album])
      flash[:notice] = 'PhotoAlbum was successfully updated.'
      redirect_to(@photo_album)
    else
      @page_title = ["Fotoalbum aanpassen", "Fotoalbums"]
			@title_error = true if @photo_album.errors[:title]
			@description_error = true if @photo_album.errors[:description]
			@preview_picture_error = true if @photo_album.errors[:preview_picture]
      render :action => "edit"
    end
  end


  # DELETE /photo_albums/1
  def destroy
		return redirect_to :action => 'index' if params[:commit] == "Nee, niet verwijderen"
    
		@photo_album = PhotoAlbum.find_by_id params[:id]
    
		if @photo_album
			validate_author @photo_album
			remove_images @photo_album.preview_picture
			@photo_album.destroy
      flash[:notice] = 'Foto album succesvol verwijderd.'
    else
      flash[:error] = 'Opgegeven fotoalbum om te verwijderen is niet gevonden!'
    end  
		
		redirect_to :action => 'index'
  end

  
private


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