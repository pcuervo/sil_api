class CreateUserTokens < ActiveRecord::Migration
  def change
    create_table :user_tokens do |t|
      t.string :auth_token
      t.references :user, foreign_key: true

      t.timestamps null: false
    end
  end
end
