class FixMembershipAssociations < ActiveRecord::Migration[7.1]
  def change
    # Comprobar si existe la columna order_id_id
    if column_exists?(:memberships, :order_id_id)
      # Intentar eliminar la clave foránea si existe
      begin
        remove_foreign_key :memberships, column: :order_id_id
      rescue ArgumentError => e
        puts "No se encontró clave foránea para order_id_id: #{e.message}"
        # Continuar sin error
      end
      
      # Renombrar la columna
      rename_column :memberships, :order_id_id, :order_id
      
      # Añadir la nueva clave foránea
      add_foreign_key :memberships, :orders
    end
    
    # Hacer lo mismo para customer_id_id si existe
    if column_exists?(:memberships, :customer_id_id)
      begin
        remove_foreign_key :memberships, column: :customer_id_id
      rescue ArgumentError => e
        puts "No se encontró clave foránea para customer_id_id: #{e.message}"
      end
      
      rename_column :memberships, :customer_id_id, :customer_id
      add_foreign_key :memberships, :customers
    end
  end
end
