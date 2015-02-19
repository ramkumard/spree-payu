class CreateSpreePayuinfos < ActiveRecord::Migration
  def change
    create_table :spree_payuinfos do |t|
      t.string :first_name
      t.string :last_name
      t.string :TransactionId
      t.string :PaymentId
      t.decimal :amount
      t.integer :order_id
      t.integer :user_id

      t.timestamps
    end
  end
end
