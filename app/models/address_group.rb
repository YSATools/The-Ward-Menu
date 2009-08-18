class AddressGroup < ActiveRecord::Base
  validates_presence_of :name 
  #validates_uniqueness_of :name, :scope => [:ward_id]
  validates_length_of :name, :minimum => 3

  has_many :contacts
end
