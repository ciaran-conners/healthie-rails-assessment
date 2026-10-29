class CreateSubscriptions < ActiveRecord::Migration[8.1]
  def change
    create_table :subscriptions do |t|
      t.references :provider, null: false, foreign_key: true
      t.references :client, null: false, foreign_key: true
      t.string :plan

      t.timestamps
    end
  end
end
