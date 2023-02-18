class PhotoAlbumCommentsController < ApplicationController

	
  # GET /photo_album_comments/new/1
  def new
		@page_title = ["Reactie plaatsen", "Fotoalbums"]
    @photo_album_comment = PhotoAlbumComment.new
				
		if (photo_album_from_id(params[:id]))
			@photo_album_comment.photo_album_id = params[:id]
		else
			flash[:error] = "Fotoalbum om reactie bij te plaatsen bestaat niet."
			redirect_to :controller => 'photo_albums'
		end
  end
		
	
  # GET /photo_album_comments/1/edit
  def edit
		@page_title = ["Reactie aanpassen", "Fotoalbums"]
    @photo_album_comment = photo_album_comment_from_id params[:id]
		
		if !@photo_album_comment
			flash[:error] = 'Reactie om aan te passen is niet gevonden!'
      redirect_to :controller => 'photo_albums', :action => 'index'
		else
      validate_author @photo_album_comment
    end
  end

	
  # POST /photo_album_comments
  def create
    @photo_album_comment = PhotoAlbumComment.new(params[:photo_album_comment])
		@photo_album_comment.message = root_src_img_tag(@photo_album_comment.message)
		@photo_album_comment.user_id = current_user.id
		
		if @photo_album_comment.save
			flash[:notice] = 'Reactie is succesvol toegevoegd.'
			redirect_to :controller => 'photo_albums', :action => 'show', :id => @photo_album_comment.photo_album_id
		else
			@page_title = ["Reactie plaatsen", "Fotoalbums"]
			flash[:error] = 'Een reactie moet wel tekst bevatten!'
			render :action => "new"
		end
  end
	
	
  # PUT /photo_album_comments/1
  def update
    @photo_album_comment = photo_album_comment_from_id params[:photo_album_comment][:id]
		params[:photo_album_comment][:message] = root_src_img_tag(params[:photo_album_comment][:message])
		
		if !@photo_album_comment
      flash[:error] = 'Reactie om aan te passen is niet gevonden!'
      redirect_to :controller => 'photo_albums', :action => 'index'    
    else
      validate_author @photo_album_comment
      if @photo_album_comment.update_attributes(params[:photo_album_comment])
        flash[:notice] = 'Uw reactie is succesvol aangepast.'
        redirect_to :controller => 'photo_albums', :action => 'show', :id => @photo_album_comment.photo_album.id
      else
        @page_title = ["Reactie aanpassen", "Fotoalbums"]
        flash[:error] = 'Een reactie moet wel tekst bevatten!'
        render :action => "edit"
      end
    end
  end
	
	
	# GET /photo_album_comments/remove/:id
  def remove
    @page_title = ["Reactie verwijderen", "Fotoalbums"]
    @photo_album_comment = photo_album_comment_from_id params[:id]
    if !@photo_album_comment
      flash[:error] = "Opgegeven reactie om te verwijderen bestaat niet"
      redirect_to :controller => 'photo_albums', :action => 'index'    
    else
      validate_author @photo_album_comment
    end
  end
	
	
  # DELETE /photo_album_comments/1
  def destroy
		@photo_album_comment = photo_album_comment_from_id params[:id]
    if !@photo_album_comment
      flash[:error] = "Opgegeven reactie om te verwijderen bestaat niet"
      redirect_to :controller => 'photo_albums', :action => 'index'
    else      
      validate_author @photo_album_comment
      return redirect_to :controller => 'photo_albums', :action => 'show', :id => @photo_album_comment.photo_album_id if params[:commit] == "Nee, niet verwijderen"
      photo_album_id = @photo_album_comment.photo_album.id
      @photo_album_comment.destroy
      flash[:notice] = "Uw reactie is succesvol verwijderd."
      redirect_to :controller => 'photo_albums', :action => 'show', :id => photo_album_id
    end
  end
	
	
private


	def photo_album_from_id(id)
    begin
      PhotoAlbum.find(id)
    rescue Exception => e
      nil
    end
  end
  
	
  def photo_album_comment_from_id(id)
    begin
      PhotoAlbumComment.find(id)
    rescue Exception => e
      nil
		end
	end 
	
	
end
