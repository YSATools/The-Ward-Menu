class Calling < ActiveRecord::Base
  has_and_belongs_to_many :contacts
  belongs_to :calling_type
end
