class TightenConstraints < ActiveRecord::Migration[8.1]
  def change
    change_column_null :subscriptions, :plan, false, "basic"
    change_column_default :subscriptions, :plan, from: nil, to: "basic"
    add_index :subscriptions, [ :provider_id, :client_id ], unique: true
    change_column_null :journal_entries, :body, false, ""
  end
end
