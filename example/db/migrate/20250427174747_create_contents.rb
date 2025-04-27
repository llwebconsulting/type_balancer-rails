class CreateContents < ActiveRecord::Migration[8.0]
  def change
    create_table :contents do |t|
      t.string :title
      t.string :category
      t.string :content_type

      t.timestamps
    end
  end
end
