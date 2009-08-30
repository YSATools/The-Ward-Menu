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
    # TODO in Ldsorg.rb / here: Notify if they have a valid old account, but need to upgrade to LDSAccount
    flash[:notice] = "Login successful!"

    # Stake & Wards
    @stake = Stake.find_or_create_by_name(@ldsorg.stake_name)
    @ldsorg.wards_in_stake.each do |ward|
      w = Ward.find_or_create_by_name(ward)
      w.stake = @stake
      w.save
    end
    @stake.save

    # Ward & Members
    i = 0
    ward = Ward.find_by_name(@ldsorg.ward_name)
    while ward.partial? do
      if ward.updated_at < 15.seconds.ago || i > 300
        #log timed out
        ward.drop_contacts
        break
      end
      i += 2
      sleep 2
      ward = Ward.find_by_name(@ldsorg.ward_name)
    end
    @ward = Ward.find_by_name(@ldsorg.ward_name)
    if @ward.stale? #or params[:user_session][:force_download]
      # NOTE if I change this to @ward.destroy, I have to relink the new one to each user
      @ward.drop_contacts
      #@ward.destroy
      #@ward = Ward.new({:name => @ldsorg.ward_name})
      #@ward.stake = @stake
      #@ward.save # update time is after directory uploads
    end
    if @ward.empty? # if the ward is empty of contacts
      download_directory
    end

    # User & Member
    # TODO BUG anomaly: First Last Jr w/ Family E-Mail
    contact = Contact.find(:first, :conditions => @ldsorg.user_profile)
    user = User.find_or_create_by_login(params[:user_session][:login])
    contact.user = user
    contact.save

    # Double Check
    #assert user.contact
    #assert user.contact.ward
    #assert user.contact.ward.contacts
    #assert user.contact.ward.stake
    #assert user.contact.ward.stake.wards
    flash[:notice] = "Login successful! + Ward Partial: " + @ward.partial?.to_s

    # All Systems Go!
    @user_session = UserSession.create(user, true)
    Contact.current_user = current_user
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
    # TODO don't delete custom additions
    # update rather than delete?

    @ldsorg.directory_init #takes about 10 seconds in links2
    #@ldsorg.directory_length
    contacts = []
    while record = @ldsorg.directory_next
      abort contact.errors unless contact = Contact.new(record)
      name = contact.address_line_1 ? contact.address_line_1 : 'default'
      contact.address_group = AddressGroup.find_or_create_by_name(name)
      contact.ward = @ward
      contact.save
      abort "A member from the directory could not be saved..." +
        " I guess they don't make it to Celestial glory..." unless contact.save
      contacts << contact
    end
    @ward.updated_at = Time.now and @ward.save

    #spawn do # TODO Queue w/ 10 minute limit
    # Link Ward Members to their photos
      for contact in contacts
        if not contact.photo.data
          #TODO contact.photo.data = File.open('images/anonymous.png').read
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
    # Link Ward Members to their Callings
      @ldsorg.calling_types.each do |t|
        type = CallingType.find_or_create_by_name(t)
        @ldsorg.callings_for_type(t).each do |tuple|
          calling = Calling.find_or_create_by_name(tuple[:calling_name])
          #if not type.callings.include? calling
            type.callings << calling
            type.save
          #end
          contact = Contact.find(:first, :conditions => tuple[:contact])
          if not contact
            logger.error tuple.inspect
          else
            contact.callings << calling
            contact.save
          end
        end
      end
    #end
  end
end
