class CreateAddressGroups < ActiveRecord::Migration
  def self.up
    create_table :address_groups do |t|
      t.string :name
      #t.has_many :contacts

      t.timestamps
    end
  end

  def self.down
    drop_table :address_groups
  end
end
