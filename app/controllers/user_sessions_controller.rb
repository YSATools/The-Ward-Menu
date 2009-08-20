class UserSessionsController < ApplicationController
  require 'ldsorg'
  skip_before_filter :require_user
  # before_filter :require_no_user, :only => [:new, :create]
  before_filter :require_user, :only => :destroy

  def index
    @user = current_user
  end

  def new
    @user_session = UserSession.new
  end

  def create
    # Login
    @ldsorg = Ldsorg.new(params[:user_session][:login], params[:user_session][:password])
    if not @ldsorg.ldslogin
      flash[:notice] = "Login failed!"
      self.new
      render :action => :new
      return
    end
    flash[:notice] = "Login successful!"


    # Build relationships
    @stake = Stake.find_or_create_by_name(@ldsorg.stake_name)
    @ldsorg.wards_in_stake.each do |ward|
      w = Ward.find_or_create_by_name(ward)
      w.stake = @stake
      w.save
    end
    @ward = Ward.find_by_name(@ldsorg.ward_name)
    if @ward.stale? or params[:user_session][:force_download]
      @ward.destroy
      @ward = Ward.new({:name => @ldsorg.ward_name})
      download_directory
    end
    @ward.stake = @stake
    @ward.save
    @user = User.find_or_create_by_login(params[:user_session][:login])
    @user.save
    @user_session = UserSession.create(@user, true)
    Contact.current_user = current_user

    if true #@ward.stale? or params[:user_session][:force_download]
      # TODO don't delete custom additions
      # update rather than delete?

      @ldsorg.directory_init #takes about 10 seconds in links2
      puts @ldsorg.directory_length
      me = Contact.new(@ldsorg.user_profile)
      contacts = []
      while record = @ldsorg.directory_next
        abort contact.errors unless contact = Contact.new(record)
        contact.save
        if contact.address_line_2
          # TODO scope to ward?
          contact.address_group = AddressGroup.find_or_create_by_name(contact.address_line_1)
          contact.address_group.save
        else
          contact.address_group = AddressGroup.find_or_create_by_name('default')
        end
        contact.ward = @ward
        # TODO BUG anomaly: First Last Jr w/ Family E-Mail
        if (contact.first == me.first) && (contact.last == me.last) && (contact.email == me.email)
          contact.user = @user
        end
        abort "A member from the directory could not be saved..." +
          " I guess they don't make it to Celestial glory..." unless contact.save
        contacts << contact
      end
      abort 'User has no contact' unless @user.contact
      @ward.updated_at = Time.now and @ward.save

      #spawn do # TODO Queue w/ 10 minute limit
        for contact in contacts
          if not contact.photo.data
            next
          end
          contact.photo.data = @ldsorg.member_photo(contact.photo.data)
          contact.photo.save
          contact.save
          @ward.updated_at = Time.now
          @ward.save
        end
        @ward.completed_at = Time.now
        @ward.save
      #end

      #spawn do
        @ldsorg.calling_types.each do |t|
          type = CallingType.find_or_create_by_name(t)
          @ldsorg.callings_for_type(t).each do |tuple|
            calling = Calling.find_or_create_by_name(tuple[:calling_name])
            #if not type.callings.include? calling
              type.callings << calling
              type.save
            #end
            contact = Contact.find(:first, :conditions => tuple[:contact])
            contact.callings << calling
            contact.save
          end
        end
      #end
    end

    redirect_to :controller => 'home', :action => 'index'
  end
  
  def destroy
    puts current_user.login
    puts current_user.ward
    current_user.ward.wards.each do |ward|
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

  private
  def download_directory
    #TODO move stuff here
  end
end
