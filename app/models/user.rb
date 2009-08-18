class User < ActiveRecord::Base
  validates_uniqueness_of :login

  #belongs_to :contact
  has_one :contact
  # TODO make this work and submit patch
  #belongs_to :ward, :through => :contact 

  # TODO create an ldsorg authlogic module
  # rather than circumventing with UserSession.create
  acts_as_authentic

  def stale?
    return @last_login_at < 72.hours.ago
    # TODO return @last_request_at < 24.hours.ago
  end
end
