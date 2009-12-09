class Ldsward
  #TODO make sure that the site is the english version
  #TODO create structs for people
  #TODO cut out all the leader_ship pages stored in memory
  require 'rubygems'
  require 'mechanize'

  #Firefox Firebug helps when the source is hard to read.
  WARD_NAME_QUERY = '/html/body/table[1]/tr/td/table/tr[6]/td/table/tr/td[7]'
  MEMBER_DIR_SEARCH = /member.*directory/i
  PHOTO_DIR_SEARCH = /photo/i
  LEADER_DIR_SEARCH = /leader.*directory/i
  MEMBER_IN_DIR_QUERY = '/html/body/table/tr/td[@class=\'eventsource\']/table/tr[1]'
  CALLING_TYPES_QUERY = '/html/body/table[2]/tr[1]/td[2]/table/tr[2]/td[2]/table[2]/tr/td/a[@class=\'channelsubfeaturetitle\']'
  CALLINGS_QUERY = '/html/body/table[2]/tr[1]/td[2]/table/tr[2]/td[2]/table[3]/tr/td[1]/table/tr[@valign=\'top\']'
  #/td[2]/a[@class=\'channelsubfeaturetitle\']'
  # Path embedded in javascript and therefore not readable by mechanize
  PHOTO_BASE_URL = 'https://secure.lds.org'

  def self.agent=(agent)
    @@agent = agent
    #WWW::Mechanize.new
    #@@agent.user_agent_alias = 'Linux Mozilla'
  end

  def initialize(name, link)
    #@agent = WWW::Mechanize.new
    #@agent.user_agent_alias = 'Linux Mozilla'
    #@agent = agent
    @name = name
    @link = link
  end

  def page
    if not @page
      @page = @link.click
    end
    @page
  end

  def page=(home_unit)
    @page = home_unit
  end

  def name
    if not @name
      @name = page.search(WARD_NAME_QUERY).inner_text.strip
    end
    @name
  end

  def leadership_page
    if not @leadership_page
      @leadership_page = page.links.find {|l| l.text =~ /Leadership Directory/}.click 
    end
    @leadership_page
  end

  #TODO don't save the directory in memory, its being passed back anyhow
  def directory
    if not @records
      dir_page = page.links.find {|l| l.text =~ MEMBER_DIR_SEARCH}.click 
      link = dir_page.links.find {|l| l.text =~ PHOTO_DIR_SEARCH}
      photo_dir_url = PHOTO_BASE_URL + /(\/.*\.html)/i.match(link.uri.to_s)[1]
      dir_page = @@agent.get(photo_dir_url)

      @records = []
      dir_page.search(MEMBER_IN_DIR_QUERY).each do |tr|
        record = {}
        name = tr.at('td[1]/table/tr[1]/td[1]').inner_text.strip
        if name.index(' ')
            record[:third] = name[0..name.index(' ')-1]
            record[:last] = name[name.index(' ')+1..name.length]
        else
            record[:third] = nil
            record[:last] = name
        end
        record[:phone] = tr.at('td[1]/table/tr[1]/td[2]').inner_text.strip
        # found funky chars (some sort of tab?) with string.inspect
        name = tr.at('td[1]/table/tr[2]/td[1]').inner_text.gsub!(/[\302\240]*/, '').strip
        if name.index(' ')
            record[:first] = name[0..name.index(' ')-1]
            record[:second] = name[name.index(' ')+1..name.length]
        else
            record[:first] = name
            record[:second] = nil
        end
        record[:email] = tr.at('td[1]/table/tr[2]/td[2]').inner_text.strip
        #address is separated by newline #TODO line 1/2 are on 1 and city/state are on 2
        full_address = tr.at('td[@width=\'25%\']').inner_text.strip.split(/\s*\n\s*/)
        #full_address = tr.at('td[@width=\'25%\']').inner_text.strip.split(/\n/)
        #puts full_address.inspect
        case full_address.length
          when 0
            record[:address_line_1] = nil
            record[:address_line_2] = nil
            record[:city], record[:state], record[:zip] = nil, nil, nil
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
            raise 'Death by more-than-3-line-address: ' + full_address.inspect
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

      #TODO use a real generator in ruby 1.9
      #TODO spawn a process to fetch photos
      #@records.each do |record_no_photo|
        #AJ BUG record_no_photo[:ward_photo] = member_photo(record_no_photo[:ward_photo_url])
      #end
    end
    @records
  end

  def photo_directory
    directory.each do |record_no_photo|
      record_no_photo[:ward_photo] = member_photo(record_no_photo[:ward_photo])
    end 
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

  def directory_length(ward_name = @ward[:name])
    directory.length
  end

  def member_photo(url)
    #if not @mystery_pic # TODO
    #  @mystery_pic = open('public/mystery_pic.jpg', "rb") {|io| io.read }
    #end
    #if not url
    #  return @mystery_pic
    #end
    @@agent.get_file(PHOTO_BASE_URL + url) if url
  end

  # TODO does each ward need one of these? I think it's just the first?
  def calling_types()
    if not @calling_types
      @calling_types = []
      leadership_page.search(CALLING_TYPES_QUERY).each {|tr| @calling_types << tr.inner_text.strip}
    end
    return @calling_types
  end

  def callings_for_type(type)
    @callings = {} unless @callings
    return @callings[type] if @callings[type]

    if not @callings[type]
      @callings[type] = []
      leadership_page = page.links.find {|l| l.text =~ /Leadership Directory/}.click unless leadership_page
      callings_page = leadership_page.links.find {|l| l.text =~ /#{type}/}.click
      callings_page.search(CALLINGS_QUERY).each do |tr| 
        calling_name = tr.at('td[1]').inner_text.strip.sub(/(.*):/, '\1')

        record = {}
        #TODO BUG I don't know why <img> turns into \302\240 or if that's just
        #a bug in the string class on my system
        #TODO look for link to determine has/not has email
        contact = tr.at('td[2]').inner_text.strip.split(/[\302\240]*\s*\n+\s*/)
        name = contact[0].split(',')
        name[0].strip!
        name[1].strip!
        if name[0].index(' ')
            record[:third] = name[0][0..name[0].index(' ')-1]
            record[:last] = name[0][name[0].index(' ')+1..name[0].length]
        else
            record[:third] = nil
            record[:last] = name[0]
        end
        if name[1].index(' ')
            record[:first] = name[1][0..name[1].index(' ')-1]
            record[:second] = name[1][name[1].index(' ')+1..name[1].length]
        else
            record[:first] = name[1].strip
            record[:second] = nil
        end
        #TODO DRY
        case contact.length
          when 0
            abort 'A calling with no person? That\'s a fail for sure!'
          when 1
            record[:address_line_1] = nil
            record[:address_line_2] = nil
            record[:city], record[:state], record[:zip] = nil, nil, nil
          when 2
            record[:address_line_1] = nil
            record[:address_line_2] = nil
            record[:city], record[:state], record[:zip] = city_state_zip(contact[1])
          when 3
            record[:address_line_1] = contact[1]
            record[:address_line_2] = nil
            record[:city], record[:state], record[:zip] = city_state_zip(contact[2])
          when 4
            record[:address_line_1] = contact[1]
            record[:address_line_2] = contact[2]
            record[:city], record[:state], record[:zip] = city_state_zip(contact[3])
          else
            abort('Death by more-than-4-line-address')
        end
        if record[:address_line_1]
          lines = record[:address_line_1].split('#')
          if (lines.length == 2) && (not record[:address_line_2])
            # TODO BUG. Some wards put apt #s in the first line
            record[:address_line_1] = lines[0].strip
            record[:address_line_2] = '#' + lines[1].strip
          end
        end

        record[:phone] = tr.at('td[3]').inner_text.strip

        tuple = {}
        tuple[:calling_name] = calling_name
        tuple[:contact] = record

        @callings[type] << tuple
      end
    end
    @callings[type]
  end


  private
    def city_state_zip(line)
      city, state, zip = nil, nil, nil
      return city, state, zip unless line
      parts = line.split(',')
      return city, state, zip unless parts[0]
      city = parts[0].strip
      return city, state, zip unless parts[1]
      parts2 = parts[1].strip.split(' ') 
      return city, state, zip unless parts2[0]
      state = parts2[0]
      return city, state, zip unless parts2[1]
      zip = parts2[1] unless 2 != parts2.length
      return city, state, zip
    end
end
