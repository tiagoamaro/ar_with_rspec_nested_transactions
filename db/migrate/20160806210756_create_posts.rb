class CreatePosts < ActiveRecord::Migration[5.0]
  def change
    create_table :posts do |t|
      t.string :title, default: ''
      t.text :content

      t.timestamps
    end

    add_index :posts, :title, unique: true
  end
end
