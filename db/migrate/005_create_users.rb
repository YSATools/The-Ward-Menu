class CreateUsers < ActiveRecord::Migration
  #http://github.com/binarylogic/authlogic_example/blob/9b22672cd64fb31b405c000e207b2cae281baa58/README.rdoc
  def self.up
    create_table :users do |t|
      t.string :login
      t.string :persistence_token
      t.string :single_access_token

      t.integer :failed_login_count
      t.integer :login_count
      t.datetime :last_login_at
      t.datetime :last_request_at

      t.belongs_to :contact #TODO pick one or the other
      t.timestamps
    end
  end

  def self.down
    drop_table :users
  end
end
