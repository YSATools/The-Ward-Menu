class Ward < ActiveRecord::Base
  validates_presence_of :name
  validates_uniqueness_of :name, :scope => [:stake_id]
  validates_length_of :name, :minimum => 3 #TODO what's a sane length

  belongs_to :stake
  has_many :contacts, :dependent => :destroy 
  has_many :callings, :through => :contacts #some callings belong to stake
  # TODO
  has_many :users, :through => :contacts, :source => :user
  #TODO
  #has_many :wards, :through => :stake

  def stale?
    if not self.completed_at
      return true
    end
    if not self.updated_at
      return true
    end
    return self.updated_at < 72.hours.ago
  end
end
