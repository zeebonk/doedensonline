class NewsController < ApplicationController

  before_filter :current_user
  before_filter :load_news_item,            :only => [:edit, :update, :remove, :destroy]
  before_filter :check_news_item_author,    :only => [:edit, :update, :remove, :destroy]
  before_filter :load_news_comment,         :only => [:edit_comment, :update_comment, :remove_comment, :destroy_comment]
  before_filter :check_news_comment_author, :only => [:edit_comment, :update_comment, :remove_comment, :destroy_comment]

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
      	Mailer.notify_new_news(target.email, @news_item, current_user).deliver if target != current_user
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
  end

  # POST /news/update
  def update
    params[:news_item][:message] = root_src_img_tag(params[:news_item][:message])
    if @news_item.update_attributes(params[:news_item])
      flash[:notice] = 'Het nieuwtje is succesvol aangepast.'
      redirect_to :action => "index"
    else
      @page_title = ["Nieuwtje aanpassen", "Nieuwtjes"]
      flash[:error] = 'Let op: een nieuwtje moet wel tekst bevatten!'
      render :action => "edit"
    end
  end

  # GET /news/remove/:id
  def remove
    @page_title = ["Nieuwtje verwijderen", "Nieuwtjes"]
  end

  # POST /news/destroy
  def destroy
    return redirect_to :action => 'index' if params[:commit] == "Nee, niet verwijderen"
    for news_comment in @news_item.news_comments
      news_comment.destroy
    end
    @news_item.destroy
    flash[:notice] = 'Nieuwtje succesvol verwijderd.'
    redirect_to :action => 'index'
  end

  # GET /news/view/:id
  def view
    @page_title = ["Nieuwtje bekijken", "Nieuwtjes"]
    @news_item = news_item_by_id params[:id]
    if !@news_item
      flash[:error] = 'Opgegeven nieuwtje is niet gevonden!'
      redirect_to :action => 'index'
    else
      @news_comments = NewsComment.where("news_item_id = ?", @news_item.id).order('created_at ASC').all
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
  end

  # POST /news/update_comment
  def update_comment
    params[:news_comment][:message] = root_src_img_tag(params[:news_comment][:message])
    if @news_comment.update_attributes(params[:news_comment])
      flash[:notice] = 'Uw reactie is succesvol aangepast.'
      redirect_to :action => 'view', :id => @news_comment.news_item.id
    else
      @page_title = ["Reactie aanpassen", "Nieuwtjes"]
      flash[:error] = 'Een reactie moet wel tekst bevatten!'
      render :action => "edit_comment"
    end
  end

  # GET /news/remove_comment/:id
  def remove_comment
    @page_title = ["Reactie verwijderen", "Nieuwtjes"]
  end

  # POST /news/destroy_comment
  def destroy_comment
    return redirect_to :action => 'view', :id => @news_comment.news_item.id if params[:commit] == "Nee, niet verwijderen"
    news_item_id = @news_comment.news_item.id
    @news_comment.destroy
    flash[:notice] = "Uw reactie is succesvol verwijderd."
    redirect_to :action => 'view', :id => news_item_id
  end


private


  def load_news_item
    id = params[:id] || (params[:news_item] && params[:news_item][:id])
    @news_item = NewsItem.find_by_id(id)
    unless @news_item
      flash[:error] = 'Opgegeven nieuwtje is niet gevonden!'
      redirect_to :action => 'index'
    end
  end

  def check_news_item_author
    user_is_author @news_item
  end

  def load_news_comment
    id = params[:id] || (params[:news_comment] && params[:news_comment][:id])
    @news_comment = NewsComment.find_by_id(id)
    unless @news_comment
      flash[:error] = 'Opgegeven reactie is niet gevonden!'
      redirect_to :action => 'index'
    end
  end

  def check_news_comment_author
    user_is_author @news_comment
  end

  def news_item_by_id(id)
    begin
      NewsItem.find(id)
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
