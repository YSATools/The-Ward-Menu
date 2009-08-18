# http://railscasts.com/episodes/47-two-many-to-many 
class CreateCallingsContacts < ActiveRecord::Migration
  def self.up
    create_table :callings_contacts, :id => false do |t|
      t.integer :calling_id
      t.integer :contact_id
    end
  end

  def self.down
    drop_table :callings_contacts
  end
end
