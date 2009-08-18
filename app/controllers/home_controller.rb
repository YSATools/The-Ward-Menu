class HomeController < ApplicationController
  skip_before_filter :require_user
  layout "main"
  
  def index
    @partial_account = "user_sessions/show"
    if @user_session = UserSession.find
      #abort 'display account info'
    else
      @partial_account = "user_sessions/new"
      @user_session = UserSession.new
      #abort 'make template for login page'
    end
  end

  def destroy
    puts current_user.login
    puts current_user.contact.ward
    current_user.contact.ward.stake.wards.each do |ward|
      puts ward
      fresh = false
      ward.users.each do |user|
        puts user.login
        if (user != current_user) && (not user.stale?)
          fresh = true
          puts user.login
        end
      end
      ward.destroy unless fresh
    end
    current_user_session.destroy
    flash[:notice] = "Logout successful!"
    #redirect_back_or_default new_user_session_url
    redirect_to :controller => 'home', :action => 'index'
  end

end
