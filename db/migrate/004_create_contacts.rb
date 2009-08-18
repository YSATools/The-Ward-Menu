class CreateContacts < ActiveRecord::Migration
  def self.up
    create_table :contacts do |t|
      t.string :first
      t.string :middle
      t.string :last
      t.string :phone
      t.string :email
      t.string :address_line_1  # Street
      t.string :address_line_2  # Apt
      t.string :city
      t.string :state
      t.string :zip
      #t.references :city
      #t.references :zip # len 5+4

      t.belongs_to :ward
      t.belongs_to :address_group
      t.belongs_to :user # undo later?
      t.timestamps
    end
  end

  def self.down
    drop_table :contacts
  end
end
