class Ldsorg
  require 'mechanize'
  require 'generator'

  LOGIN_URL = 'https://secure.lds.org/units/login'
  #Firefox Firebug helps when the source is hard to read.
  STAKE_NAME_QUERY = '/html/body/table[1]/tr/td/table/tr[6]/td/table/tr/td[5]'
  WARD_NAME_QUERY = '/html/body/table[1]/tr/td/table/tr[6]/td/table/tr/td[7]'
  MEMBER_DIR_SEARCH = /member.*directory/i
  PHOTO_DIR_SEARCH = /photo/i
  MY_ACCOUNT_SEARCH = /Update Profile/
  MEMBER_IN_DIR_QUERY = '/html/body/table/tr/td[@class=\'eventsource\']/table/tr[1]'
  WARDS_IN_STAKE_QUERY = '/html/body/table[2]/tr/td[2]/table/tr[2]/td[2]/table[2]/tr/td/a[@class=\'featuressubtitle\']'
  # Path embedded in javascript and therefore not readable by mechanize
  PHOTO_BASE_URL = 'https://secure.lds.org'

  attr_accessor :stake_name, :ward_name

  def initialize(ldsaccount, password)
    @agent = WWW::Mechanize.new
    @agent.user_agent_alias = 'Linux Mozilla'
    begin
      @unit_page = @agent.get(LOGIN_URL)
    rescue Exception
      @msg = "LDS.org is not replying. It may be down for maintenance. If so, come back later."
      abort @msg
    end

    ## Class Variables
    @ldsaccount = ldsaccount
    @password = password
    @result = false
    @records = nil
  end

  def ldslogin
    login_page = @agent.get('https://secure.lds.org/units/login')
    form = login_page.forms.find {|f| f.name = 'loginForm'}             # Find the login form
    if not (( form.has_field? 'username' ) && ( form.has_field? 'password' ))
        abort 'LDS.org has been updated and this script has not. It is borken! :('
    end
    form['username'] = @ldsaccount                                      # Enter the username
    form['password'] = @password                                        # Enter the password
    @unit_page = form.submit                                            # Try to login

    if /login/i.match(@unit_page.title)                                 # Check for a failed login
      return false
    end

    @stake_name = @unit_page.search(STAKE_NAME_QUERY).inner_text.strip
    @ward_name = @unit_page.search(WARD_NAME_QUERY).inner_text.strip
    # TODO regex from var
    @wards_link =@unit_page.links.find {|l| 
      l.text =~ /.*Stake.*/
    }
    return true
  end

  def wards_in_stake
    if not @wards
      @wards = []
      page = @wards_link.click
      page.search(WARDS_IN_STAKE_QUERY).each do |a|
        @wards << a.inner_text.strip
      end
    end
    return @wards
  end

  # Speed vs Progress Feedback
  # We can either get the whole directory as text
  #   which gives us the total count
  #   and therefore a possible progress bar
  #   and it's easier to attach our user to its account
  #   but we have to wait for the complete text to download
  #   and will download later
  # Or we can get each 'each' cycle
  #   which gives us a faster start
  #   and will download pics at the same time
  #   but gives us no count

  def directory_length
    return @records.length
  end

  def directory_init
    directory_init_helper
  end

  def directory_next
    #TODO this generator can be moved to enclose the each loop
    if not @directory_gen
      directory_init_helper
    end
    return @directory_gen.next
  end

  def photo_directory_next
    if not @directory_gen
      directory_init_helper
    end
    if not @photo_directory_gen
      photo_directory_generator
    end
    return @photo_directory_gen.next
  end

  def member_photo(url)
    return @agent.get_file(PHOTO_BASE_URL + url)
  end

  def user_profile
    profile_page = @unit_page.links.find {|l| l.text =~ MY_ACCOUNT_SEARCH}.click
    form = profile_page.forms.find {|f| f.name = 'profileForm'}
    last_query = 'html/body/table[2]/tr[1]/td[2]/table/tr[2]/td[2]/table/tr[1]/td[1]/table/tr/td[1]/form/table/tr[1]/td[2]/span'

    record = {}
    record[:first] = form['prefName'].strip
    record[:last] = profile_page.search(last_query).inner_text.strip
    record[:email] = form['email'].strip

    return record
  end

  private
    def city_state_zip(line)
      city, state, zip = nil, nil, nil
      parts = line.split(',')
      city = parts[0].strip
      parts2 = parts[1].strip.split(' ')
      state = parts2[0]
      zip = parts2[1] unless 2 != parts2.length
      return city, state, zip
    end

    def directory_init_helper
      #Assuming that we're still on the ward page and going to the membership dir
      if not @unit_page
        abort 'No unit page found. Was the login valid?' #todo - valid login result
      end
      page = @unit_page.links.find {|l| l.text =~ MEMBER_DIR_SEARCH}.click 
      link = page.links.find {|l| l.text =~ PHOTO_DIR_SEARCH}
      photo_dir_url = PHOTO_BASE_URL + /(\/.*\.html)/i.match(link.uri.to_s)[1]
      page = @agent.get(photo_dir_url)

      @records = []
      page.search(MEMBER_IN_DIR_QUERY).each do |tr|
          record = {}
          record[:last] = tr.at('td[1]/table/tr[1]/td[1]').inner_text.strip
          record[:phone] = tr.at('td[1]/table/tr[1]/td[2]').inner_text.strip
          # found funky chars (some sort of tab?) with string.inspect
          name = tr.at('td[1]/table/tr[2]/td[1]').inner_text.gsub!(/[\302\240]/, '').strip
          if name.index(' ')
              record[:first] = name[0..name.index(' ')-1]
              record[:middle] = name[name.index(' ')+1..name.length]
          else
              record[:first] = name
              record[:middle] = nil
          end
          record[:email] = tr.at('td[1]/table/tr[2]/td[2]').inner_text.strip
          #address is separated by newline #TODO line 1/2 are on 1 and city/state are on 2
          full_address = tr.at('td[@width=\'25%\']').inner_text.strip.split(/\n/)
          case full_address.length
            when 0
              record[:address_line_1] = nil
              record[:address_line_2] = nil
              record[:city], record[:state], record[:zip] = nil, nil, nil
              #record[:city_name], record[:state_name], record[:zip_name] = nil, nil, nil
            when 1
              record[:address_line_1] = nil
              record[:address_line_2] = nil
              record[:city], record[:state], record[:zip] = city_state_zip(full_address[0])
            when 2
              record[:address_line_1] = full_address[0]
              record[:address_line_2] = nil
              record[:city], record[:state], record[:zip] = city_state_zip(full_address[1])
            when 3
              record[:address_line_1] = full_address[0]
              record[:address_line_2] = full_address[1]
              record[:city], record[:state], record[:zip] = city_state_zip(full_address[2])
            else
              abort('Death by more-than-3-line-address')
          end

          if record[:address_line_1]
            lines = record[:address_line_1].split('#')
            if (lines.length == 2) && (not record[:address_line_2])
              # TODO BUG. Some wards put apt #s in the first line
              record[:address_line_1] = lines[0].strip
              record[:address_line_2] = '#' + lines[1].strip
            end
          end

          record[:ward_photo] = nil
          if img = tr.at('img') 
            record[:ward_photo] = img['src']
          end
          @records << record
      end

      @directory_gen = Generator.new do |d|
        @records.each do |record_no_photo|
          d.yield record_no_photo
        end
        d.yield nil
      end
    end

    def photo_directory_generator
      @photo_directory_gen = Generator.new do |p|
        for record in @records
          if record[:ward_photo] 
            record[:ward_photo] = @agent.get_file(PHOTO_BASE_URL + record[:ward_photo])
          end
          p.yield record
        end
        p.yield nil
      end
    end
end
