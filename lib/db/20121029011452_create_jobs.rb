class CreateJobs < ActiveRecord::Migration
  def change
    create_table :jobs do |t|
      t.string  :uid
      t.string  :test_type
      t.integer :priority
      t.integer :number
      t.string  :title
      t.string  :ssh_url
      t.string  :branch
      t.string  :commit

      t.timestamps
    end
  end
end
