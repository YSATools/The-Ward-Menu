class Contact < ActiveRecord::Base
  #http://groups.google.com/group/authlogic/browse_thread/thread/dd844e966bd2687f?hl=en
  cattr_accessor :current_user
  #default_scope :conditions => ["ward_id IN (?)", @@current_user.contact.ward.stake.wards]
  if @@current_user
    default_scope :conditions => ["ward_id IN (?)", @@current_user.contact.ward.stake.wards]
    abort 'the dynamic default scoping works'
  end

  validates_presence_of :first, :last  
  #validates_uniqueness_of :ward_id, :scope => [:last, :first]
  #validates_length_of :first, :minimum => 1 # P Fallon Jenson... that's a real name
  #validates_length_of :last, :minimum => 1 # Jet Li... and there are even 1 letter last names!!!

  belongs_to :address_group
  belongs_to :ward
  # TODO
  #belongs_to :stake, :through => :ward
  belongs_to :user
  #has_one :user
  has_one :photo
  has_and_belongs_to_many :callings

  def current_scope(current_user)
    @@current_user = current_user
    default_scope :conditions => ["ward_id IN (?)", @@current_user.contact.ward.stake.wards]
  end

  def ward_name=(name)
    @ward = find_or_create_by_name(name)
  end

  def image_file=(input_data)
    record = {}
    record[:filename] = input_data.original_filename
    record[:content_type] = input_data.content_type.chomp
    record[:data] = input_data.read
    photo = Photo.new(record)
    photo.save
    self.photo = photo
  end

  def ward_photo=(download)
    record = {}
    record[:filename] = self.first + '_' + self.last + '.jpg'
    record[:content_type] = 'image/jpeg'
    record[:data] = download
    photo = Photo.new(record)
    photo.save
    self.photo = photo
  end
end
