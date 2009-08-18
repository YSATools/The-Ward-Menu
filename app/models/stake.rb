class Stake < ActiveRecord::Base
    validates_presence_of :name
    validates_uniqueness_of :name
    validates_length_of :name, :minimum => 3 #TODO what's a sane length

    has_many :wards, :dependent => :destroy
    has_many :contacts, :through => :wards
end
