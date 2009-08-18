class LoginController < ApplicationController
  def index
    if request.post? and params[:user]
      ldsaccount = params[:user]
      @is_valid, @msg = test_lds_account(ldsaccount['username'], ldsaccount['password'])

      if @is_valid
        ldsaccount['ward'] = @msg
        @user = User.new(ldsaccount)
        if @user.save
          flash[:notice] = "User created. Welcome from " + @msg
        else
          flash[:notice] = "Existing User. Welcome from " + @msg
        end
      end
      
      flash[:error] = @msg
      redirect_to :controller => "contacts"
    end
  end

  private

  def test_lds_account(username, password)
    require 'mechanize'
    agent = WWW::Mechanize.new
    agent.user_agent_alias = 'Mac Safari'
    # Start at the main LDS.org page
    begin
      page = agent.get('http://lds.org/')
    rescue Exception
      return false, "LDS.org is not replying. It may be down for maintenance. If so, come back later."
    end

    page = page.links.find {|l| l.text =~ /ward.*site/i}.click          # Go to the login page
    form = page.forms.find {|f| f.name =~ /log/i}                       # Find the login form
    form.fields.find {|f| f.name =~ /user/i}.value = username           # Enter the username
    form.fields.find {|f| f.name =~ /pass/i}.value = password           # Enter the password
    page = form.submit                                                  # Try to login

    # Check for a failed login
    if /login/i.match(page.title)
      @msg = 'Check your username and password.'
      if User.find_by_username(username)
        @msg = 'The username seems good, check your password.'
      end
      return false, "Unable to login: " + @msg
    end

    #puts "Navigating to the membership directory..."
    page = page.links.find {|l| l.text =~ /member.*directory/i}.click   # Go to the membership directory page
    link = page.links.find {|l| l.text =~ /photo/i}                     # Find the link to the version of the directory with the photos


    # The actual URL for the photo directory is embedded in javascript
    # in the HREF field. So we have to dig it out ourselves.
    # TODO Can we pull the base of the URI from the agent (or page)
    # instead of hard coding it?
    photo_directory_url = 'https://secure.lds.org' + /(\/.*\.html)/i.match(link.uri.to_s)[1]
    page = agent.get(photo_directory_url)


    #puts "Downloading the pictures (this can take several minutes)..."
    # Yes, this page actually has _two_ HTML title elements!
    ward_name = page.search('/html/head/title[1]').inner_text.strip
    ward_name.slice!(' Membership Directory')

    if @ward = Ward.find_by_name(ward_name)
        #abort 'found existing ward'
        @seconds_from_update = Time.now.to_i - Time.at(@ward.updated_at.to_i).to_i
        if @seconds_from_update < 1.day.to_i
            return true, ward_name
        end
        #abort 'ward too old, downloading again'
    end

    #TODO spawn, inform user of wait, track progress
    _FAMILY_QUERY = '/html/body/table/tr/td[@class=\'eventsource\']/table/tr[1]'
    spawn do
        page.search(_FAMILY_QUERY).each do |tr|
            record = {}
            record[:ward_name] = ward_name
            record[:last] = tr.at('td[1]/table/tr[1]/td[1]').inner_text.strip
            record[:phone] = tr.at('td[1]/table/tr[1]/td[2]').inner_text.strip
            # found funky chars with string.inspect
            record[:first] = tr.at('td[1]/table/tr[2]/td[1]').inner_text.gsub!(/[\302\240]/, '').strip
            record[:email] = tr.at('td[1]/table/tr[2]/td[2]').inner_text.strip
            record[:address] = tr.at('td[@width=\'25%\']').inner_text.strip.split(/\n/)[0]
            #_alias = "#{first} #{last}"
            record[:ward_photo] = nil
            if img = tr.at('img') # No, I don't mean == here
                record[:ward_photo] = agent.get_file('https://secure.lds.org' + img['src']) # TODO don't hard code the base of the uri
            end 
            @contact = Contact.new( record )
            @contact.save
            #Flash: Added 'First Last'
        end
        #Flash: Added Num members
    end

          
    return true, ward_name
          
  end
end
