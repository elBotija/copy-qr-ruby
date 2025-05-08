class RemoveDuplicateShippingInfosAndUpdateIndex < ActiveRecord::Migration[7.1]
  def up
    # Primero, encontrar y eliminar registros duplicados
    # Conservamos solo el registro más reciente para cada order_id
    ShippingInfo.connection.execute(<<-SQL)
      DELETE FROM shipping_infos
      WHERE id NOT IN (
        SELECT MAX(id)
        FROM shipping_infos
        GROUP BY order_id
      )
    SQL

    # Verificar si ya existe un índice y eliminarlo
    if index_exists?(:shipping_infos, :order_id)
      remove_index :shipping_infos, :order_id
    end

    # Crear un nuevo índice único
    add_index :shipping_infos, :order_id, unique: true
  end

  def down
    # Si necesitamos revertir, simplemente volvemos a crear un índice no único
    remove_index :shipping_infos, :order_id
    add_index :shipping_infos, :order_id
  end
end