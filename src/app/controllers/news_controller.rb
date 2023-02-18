class NewsController < ApplicationController  

  before_filter  :current_user

  # GET /news/
  def index
    @page_title = ["Nieuwtjes overzicht", "Nieuwtjes"]
    @news_items = paginate_news
  end
  
  # GET /news/page/:page_number
  def page
    @page_title = ["Nieuwtjes overzicht", "Nieuwtjes"]
    @news_items = paginate_news
    render :action => 'index'
  end
  
  # GET /news/add
  def add
    @page_title = ["Nieuwtje toevoegen", "Nieuwtjes"]
    @news_item = NewsItem.new
  end
  
  # POST /news/create
  def create
    @news_item = NewsItem.new(params[:news_item])
    @news_item.message = root_src_img_tag(@news_item.message)
    @news_item.user_id = current_user.id

    if @news_item.save
      flash[:notice] = 'Nieuwtje succesvol toegevoegd.'
      targets = User.find_all_by_notify_news(true)
      for target in targets
      	Mailer.deliver_notify_new_news(target.email, @news_item, current_user) if target != current_user
      end
      redirect_to :action => 'index'
    else
      @page_title = ["Nieuwtje toevoegen", "Nieuwtjes"]
      flash[:error] = 'Let op: een nieuwtje moet wel tekst bevatten!'
      render :action => "add"
    end
  end

  # GET /news/edit  
  def edit
    @page_title = ["Nieuwtje aanpassen", "Nieuwtjes"]
    @news_item = news_item_by_id params[:id]

    if !@news_item
      flash[:error] = 'Op gegeven nieuwtje om aan te passen bestaat niet!'
      redirect_to :action => 'index'
    else
      validate_author @news_item    
    end
  end
  
  # POST /news/update
  def update
    @news_item = news_item_by_id params[:news_item][:id]
    params[:news_item][:message] = root_src_img_tag(params[:news_item][:message])
    if @news_item    
      validate_author @news_item
      if @news_item.update_attributes(params[:news_item])
        flash[:notice] = 'Het nieuwtje is succesvol aangepast.'
        redirect_to :action => "index"
      else
        @page_title = ["Nieuwtje aanpassen", "Nieuwtjes"]
        flash[:error] = 'Let op: een nieuwtje moet wel tekst bevatten!'
        render :action => "edit"
      end
    else
      flash[:error] = 'Opgegeven nieuwtje om aan te passen is niet gevonden!'
      redirect_to :action => "index"      
    end
  end

  # GET /news/remove/:id  
  def remove
    @page_title = ["Nieuwtje verwijderen", "Nieuwtjes"]
    @news_item = news_item_by_id params[:id]
    if !@news_item
      flash[:error] = 'Op gegeven nieuwtje om aan te verwijderen bestaat niet!'
      redirect_to :action => 'index'
    else
      validate_author @news_item
    end  
  end
  
  # POST /news/destroy
  def destroy
    return redirect_to :action => 'index' if params[:commit] == "Nee, niet verwijderen"
    @news_item = news_item_by_id params[:id]
    if @news_item
      validate_author @news_item
      for news_comment in @news_item.news_comments
        news_comment.destroy
      end
      @news_item.destroy
      flash[:notice] = 'Nieuwtje succesvol verwijderd.'
      redirect_to :action => 'index'
    else
      flash[:error] = 'Opgegeven nieuwtje om te verwijderen is niet gevonden!'
      redirect_to :action => 'index'
    end      
  end
  
  # GET /news/view/:id
  def view
    @page_title = ["Nieuwtje bekijken", "Nieuwtjes"]
    @news_item = news_item_by_id params[:id]
    if !@news_item
      flash[:error] = 'Op gegeven nieuwtje om te bekijken bestaat niet!'
      redirect_to :action => 'index'
    else
      @news_comments = NewsComment.find :all, :conditions => ["news_item_id = ?", @news_item.id], :order => 'created_at ASC'
    end
  end
 
  # GET /news/add_comment
  def add_comment
    @page_title = ["Reactie plaatsen", "Nieuwtjes"]
    @news_comment = NewsComment.new
    @news_comment.news_item_id = params[:id]
  end
  
  # POST /news/create_comment
  def create_comment
    @news_comment = NewsComment.new(params[:news_comment])
    @news_comment.message = root_src_img_tag(@news_comment.message)
    @news_comment.user_id = current_user.id

    if @news_comment.save
      flash[:notice] = 'Reactie is succesvol toegevoegd.'
      redirect_to :action => 'view', :id => @news_comment.news_item_id
    else
      @page_title = ["Reactie plaatsen", "Nieuwtjes"]
      flash[:error] = 'Een reactie moet wel tekst bevatten!'
      @news_item = NewsItem.find(@news_comment.news_item_id)
      render :action => "add_comment"
    end
  end
  
  # GET /news/edit_comment/:id
  def edit_comment
    @page_title = ["Reactie aanpassen", "Nieuwtjes"]
    @news_comment = news_comment_by_id params[:id]
    if !@news_comment
      flash[:error] = 'Reactie om aan te passen is niet gevonden!'
      redirect_to :action => 'index'
    else
      validate_author @news_comment
    end
  end
  
  # POST /news/update_comment
  def update_comment
    @news_comment = news_comment_by_id params[:news_comment][:id]
    params[:news_comment][:message] = root_src_img_tag(params[:news_comment][:message])
    if !@news_comment
      flash[:error] = 'Reactie om aan te passen is niet gevonden!'
      redirect_to :action => 'index'    
    else
      validate_author @news_comment
      if @news_comment.update_attributes(params[:news_comment])
        flash[:notice] = 'Uw reactie is succesvol aangepast.'
        redirect_to :action => 'view', :id => @news_comment.news_item.id
      else
        @page_title = ["Reactie aanpassen", "Nieuwtjes"]
        flash[:error] = 'Een reactie moet wel tekst bevatten!'
        render :action => "edit_comment"
      end
    end
  end
  
  # GET /news/remove_comment/:id
  def remove_comment
    @page_title = ["Reactie verwijderen", "Nieuwtjes"]
    @news_comment = news_comment_by_id params[:id]
    if !@news_comment
      flash[:error] = "Opgegeven reactie om te verwijderen bestaat niet"
      redirect_to :action => 'index'    
    else
      validate_author @news_comment
    end
  end
  
  # POST /news/destroy_comment
  def destroy_comment
    @news_comment = news_comment_by_id params[:id]
    if !@news_comment
      flash[:error] = "Opgegeven reactie om te verwijderen bestaat niet"
      redirect_to :action => 'index'
    else      
      validate_author @news_comment
      return redirect_to :action => 'view', :id => @news_comment.news_item.id if params[:commit] == "Nee, niet verwijderen"
      news_item_id = @news_comment.news_item.id
      @news_comment.destroy
      flash[:notice] = "Uw reactie is succesvol verwijderd."
      redirect_to :action => 'view', :id => news_item_id
    end
  end
  
	
private


  def news_item_by_id(id)
    begin
      NewsItem.find(id)
    rescue Exception => e
      nil
    end
  end
  
  def news_comment_by_id(id)
    begin
      NewsComment.find(id)
    rescue Exception => e
      nil
    end  
  end
  
  def paginate_news
    if params[:page_number]
      @page = params[:page_number].to_i
    else
      @page = 1
    end
    @news_per_page = 6
    @pages = (NewsItem.all.count.to_f / @news_per_page).ceil
    offset = (@page - 1) * @news_per_page
    NewsItem.latest(@news_per_page, offset)
  end
    
end
