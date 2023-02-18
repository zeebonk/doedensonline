class PhotoAlbumPicturesController < ApplicationController

  layout 'default'


  # GET /photo_album_pictures/1
  def show
    @page_title = ["Foto's beheren", "Fotoalbums"]
  	@photo_album = PhotoAlbum.find(params[:id])
  	@photo_album_picture = PhotoAlbumPicture.new  	
  	@photo_album_picture.photo_album_id = @photo_album.id
  end


  # POST /photo_album_pictures
  def create
  	@photo_album_picture = PhotoAlbumPicture.new(params[:photo_album_picture])
    
    # Picture upload
    if params[:photo_album_picture][:filename] != nil
      begin
        picture = UploadPicture.new params[:photo_album_picture][:filename]
        create_images picture
        @photo_album_picture.filename  = picture.filename
      rescue
        @photo_album_picture.errors.add(:filename, "Unsupported image selected")
      end
	end
	
	if @photo_album_picture.errors.empty? && @photo_album_picture.save
      redirect_to :action => 'show', :id => @photo_album_picture.photo_album_id
    else
      @page_title = ["Foto's beheren", "Fotoalbums"]	
      @photo_album = @photo_album_picture.photo_album
      render :action => 'show', :id => @photo_album_picture.photo_album_id
    end
  	
  end

  
  # POST /photo_album_pictures/destory_many
  def destroy_many
 		
  	@photo_album = PhotoAlbum.find_by_id params[:album]
  	
    if params[:delete]
	  for picture_id in params[:delete]
	    picture = PhotoAlbumPicture.find(picture_id)
	    remove_images picture.filename
        picture.destroy
	  end		
    end
	
    redirect_to :action => 'show', :id => @photo_album.id
    
  end
  
  
end