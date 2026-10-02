class AddAuthentication < ActiveRecord::Migration[8.1]
  def change
    # Existing accounts remain inaccessible until a password is explicitly set.
    add_column :users, :password_digest, :string

    create_table :sessions do |t|
      t.references :user, null: false, foreign_key: true
      t.string :token_digest, null: false
      t.datetime :expires_at, null: false
      t.timestamps
    end
    add_index :sessions, :token_digest, unique: true
  end
end
