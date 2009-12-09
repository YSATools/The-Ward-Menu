class Ldsorg
  require 'rubygems'
  require 'mechanize'
  require 'ldsward'

  LOGIN_URL = 'https://secure.lds.org/units/login'
  STAKE_NAME_QUERY = '/html/body/table[1]/tr/td/table/tr[6]/td/table/tr/td[5]'
  WARDS_IN_STAKE_QUERY = '/html/body/table[2]/tr/td[2]/table/tr[2]/td[2]/table[2]/tr/td/a[@class=\'featuressubtitle\']'
  MY_ACCOUNT_SEARCH = /Update Profile/

  def initialize
    @agent = WWW::Mechanize.new
    @agent.user_agent_alias = 'Linux Mozilla'
  end

  def ldslogin(ldsaccount, password)
    begin
      login_page = @agent.get(LOGIN_URL)
    rescue Exception
      @msg = "LDS.org is not replying. It may be down for maintenance. If so, come back later."
      abort @msg
    end

    # Find the login form and attempt to log in
    form = login_page.forms.find {|f| f.name = 'loginForm'}
    if not (( form.has_field? 'username' ) && ( form.has_field? 'password' ))
        raise 'They finally updated LDS.org to the new 2010 site, but we haven\'t updated ours. It is borken! :('
    end
    form['username'] = ldsaccount
    form['password'] = password
    Ldsward.agent = @agent
    @ward = Ldsward.new nil, nil
    @ward.page = form.submit

    # Check for a failed login
    if /login/i.match(@ward.page.title)
      return false
    end

    # Get stake and ward name
    name = @ward.page.search(STAKE_NAME_QUERY).inner_text.strip
    link = @ward.page.links.find {|l| l.text =~ /.*Stake.*/}
    @stake = Ldsward.new name, link
    true
  end

  def stake
    @stake
  end

  def ward
    @ward
  end

  def wards
    if not @wards
      @wards = {}
      stake.page.search(WARDS_IN_STAKE_QUERY).each do |a|
        name = a.inner_text.strip
        name_s = Regexp.escape(name)
        link = stake.page.links.find {|l| l.text =~ /.*#{name_s}.*/ }

        ward = {}
        ward = Ldsward.new name, link
        if ward.name == @ward.name
          @ward = ward
        end
        @wards[name] = ward
        puts "ward name:" + @wards[name].name
      end
    end
    @wards
  end

  def directories
    directories = []
    wards.each_pair do |name, ward|
      directories += ward.directory
    end
    directories
  end

  def user_profile
    return @user_profile unless not @user_profile
    profile_page = @ward.page.links.find {|l| l.text =~ MY_ACCOUNT_SEARCH}.click
    form = profile_page.forms.find {|f| f.name = 'profileForm'}
    last_query = 'html/body/table[2]/tr[1]/td[2]/table/tr[2]/td[2]/table/tr[1]/td[1]/table/tr/td[1]/form/table/tr[1]/td[2]/span'

    first_second = form['prefName'].strip.split('\s+')
    second = first_second[1] ? first_second[1] : nil
    third_last = profile_page.search(last_query).inner_text.strip.split('\s+')
    @user_profile = {
      :first => first_second[0],
      :second => first_second[1] ? first_second[1] : nil,
      :third => third_last[1] ? third_last[0] : nil,
      :last => third_last[1] ? third_last[1] : third_last[0],
      :email => form['email'].strip,
    }

    return @user_profile
  end
end
