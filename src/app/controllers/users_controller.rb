class UsersController < ApplicationController
  layout 'default'

  before_action :return_to_home_if_user_not_admin

  # GET /users
  def index
    @users = User.all
  end

  # GET /users/1
  def show
    @user = User.find(params[:id])
  end

  # GET /users/new
  def new
    @user = User.new
  end

  # GET /users/1/edit
  def edit
    @user = User.find(params[:id])
  end

  # POST /users
  def create
    @user = User.new(user_admin_params)

    if @user.save
      flash[:notice] = t('flash.users.created')
      redirect_to(@user)
    else
      render action: "new"
    end
  end

  # PUT /users/1
  def update
    @user = User.find(params[:id])

    if @user.update(user_admin_params)
      flash[:notice] = t('flash.users.updated')
      redirect_to(@user)
    else
      render action: "edit"
    end
  end

  # DELETE /users/1
  def destroy
    @user = User.find(params[:id])
    @user.destroy

    redirect_to(users_url)
  end

  private

  def user_admin_params
    params.require(:user).permit(
      :first_name, :last_name, :email,
      :notify_news, :notify_photo_album,
      :password, :isadmin
    )
  end
end
