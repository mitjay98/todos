class AddUserToTodos < ActiveRecord::Migration[8.1]
  def up
    add_reference :todos, :user, foreign_key: true

    # Backfill existing records before requiring an owner.
    execute <<~SQL
      INSERT INTO users (name, email, created_at, updated_at)
      VALUES ('Default User', 'default@example.com', CURRENT_TIMESTAMP, CURRENT_TIMESTAMP)
      ON CONFLICT(email) DO NOTHING
    SQL
    execute <<~SQL
      UPDATE todos
      SET user_id = (SELECT id FROM users WHERE email = 'default@example.com')
      WHERE user_id IS NULL
    SQL

    change_column_null :todos, :user_id, false
  end

  def down
    remove_reference :todos, :user, foreign_key: true
  end
end
