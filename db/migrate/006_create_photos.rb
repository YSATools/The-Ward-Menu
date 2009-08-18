class CreatePhotos < ActiveRecord::Migration
  def self.up
    create_table :photos do |t|
      t.string :filename
      t.string :content_type
      t.binary :data

      t.references :contact
      t.timestamps
    end
  end

  def self.down
    drop_table :photos
  end
end
