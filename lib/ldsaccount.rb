class Ldsorg
  require 'rubygems'
  require 'mechanize'

  LOGIN_URL = 'https://secure.lds.org/units/login'
  MY_ACCOUNT_SEARCH = /Update Profile/

  self.def initialize
    if not @@agent
      @@agent = WWW::Mechanize.new
      @@agent.user_agent_alias = 'Linux Mozilla'
    end
    true
  end

  def ldslogin(ldsaccount, password)
    begin
      login_page = @@agent.get(LOGIN_URL)
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
    @ward = Ldsward.new nil, nil
    @ward.page = form.submit

    # Check for a failed login
    if /login/i.match(@ward.page.title)
      return false
    end

    # Get stake and ward name
    name = @ward.page.search(STAKE_NAME_QUERY).inner_text.strip
    link = @ward.page.links.find {|l| l.text =~ /.*Stake.*/}
    @stake = Ldsward.new @agent, name, link
    true
  end
end
