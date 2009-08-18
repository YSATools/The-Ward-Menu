class CreateCallings < ActiveRecord::Migration
  def self.up
    create_table :callings do |t|
      t.string :name

      t.references :callingtypes
      t.timestamps
    end
  end

  def self.down
    drop_table :callings
  end
end
