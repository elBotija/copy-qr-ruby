class AddInvoiceDataToShippingInfos < ActiveRecord::Migration[7.1]
  def change
    add_column :shipping_infos, :invoice_number, :string
    add_column :shipping_infos, :invoice_date, :date
  end
end
