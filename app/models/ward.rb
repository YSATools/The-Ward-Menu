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

  def empty?
    return contacts.nil? ? true : contacts.empty?
  end
  def stale?
    return !updated_at.nil? && updated_at < 72.hours.ago
  end
  def complete?
    return !completed_at.nil? && completed_at > 30.days.ago
  end
  def partial?
    return !empty? && !complete?
  end
  def drop_contacts
    updated_at = nil
    completed_at = nil
    contacts.each {|c| c.destroy}
    save
  end
end
