class CreateProfiles < ActiveRecord::Migration
  def self.up
    create_table :profiles do |t|
      t.string :about, :hobby
      t.integer :user_id
    end
  end
  
  def self.down
    drop_table :profiles
  end
end