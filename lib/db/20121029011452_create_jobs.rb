class CreateJobs < ActiveRecord::Migration
  def change
    create_table :jobs do |t|
      t.string  :type
      t.integer :priority

      t.timestamps
    end
  end
end
