class CreateDsElements < ActiveRecord::Migration
  def change
    create_table :ds_elements do |t|
      t.string :fullpath
      t.string :sample_value
      t.timestamps
    end
  end
end
