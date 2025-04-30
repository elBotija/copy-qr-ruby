# Require necesario para usar Faker
require 'faker'

# Verificar método de confirmación
def confirm_user(user)
  if user.respond_to?(:confirm)
    # Si el usuario tiene el método confirm (Devise confirmable)
    user.confirm
  elsif user.respond_to?(:confirmed_at=) && user.respond_to?(:save)
    # Alternativa si no tiene el método confirm directo
    user.confirmed_at = Time.now
    user.save
  end
  # Si no tiene ninguno, no hacemos nada
end

# Crear usuarios si no existen
begin
  puts "Intentando crear usuario regular..."
  
  # Comprobar si el usuario ya existe
  user_email = 'usuario@ejemplo.com'
  user = User.find_by(email: user_email)
  
  if !user
    # Crear con bloques rescue para capturar errores
    puts "El usuario no existe, creando..."
    
    # Intentar crear con atributos mínimos primero
    begin
      user = User.new(email: user_email, password: '123456', terms_of_service: true)
      user.confirm
      user.save!
      puts "Usuario regular creado exitosamente"
    rescue => e
      puts "Error al crear usuario regular: #{e.message}"
    end
  else
    puts "El usuario regular ya existe"
  end
rescue => e
  puts "Error al verificar usuario existente: #{e.message}"
end

# Hacer lo mismo para el admin
begin
  puts "Intentando crear usuario admin..."
  
  admin_email = 'admin@ejemplo.com'
  admin = User.find_by(email: admin_email)
  
  if !admin
    puts "El admin no existe, creando..."
    
    begin
      admin = User.new(email: admin_email, password: '123456', terms_of_service: true, admin: true)
      admin.confirm
      admin.save!
      puts "Usuario admin creado exitosamente"
    rescue => e
      puts "Error al crear usuario admin: #{e.message}"
    end
  else
    puts "El usuario admin ya existe"
    # Asegurarse que sea admin
    if admin.respond_to?(:admin=) && !admin.admin?
      begin
        admin.admin = true
        admin.save!
        puts "Usuario actualizado como admin"
      rescue => e
        puts "Error al actualizar como admin: #{e.message}"
      end
    end
  end
rescue => e
  puts "Error al verificar admin existente: #{e.message}"
end

# Resto del seed solo si no hay errores en los usuarios
if defined?(User) && User.find_by(email: 'usuario@ejemplo.com') && User.find_by(email: 'admin@ejemplo.com')
  
  puts "Ambos usuarios creados correctamente, continuando con el resto del seed..."
  
  # Crear memorials si el modelo existe
  user = User.find_by(email: 'usuario@ejemplo.com')
  
  if defined?(Memorial) && user && user.respond_to?(:memorials)
    begin
      if user.memorials.count == 0
        puts "Creando memorials de ejemplo..."
        5.times do
          begin
            user.memorials.create!(
              first_name: Faker::Name.first_name,
              last_name: Faker::Name.last_name,
              dob: Faker::Date.between(from: 70.years.ago, to: 20.years.ago),
              dod: Faker::Date.between(from: 19.years.ago, to: 1.day.ago),
              caption: Faker::Lorem.sentence,
              bio: Faker::Lorem.paragraph(sentence_count: 10)
            )
          rescue => e
            puts "Error al crear memorial: #{e.message}"
          end
        end
        puts "Memorials creados con éxito"
      else
        puts "Los memorials ya existen, omitiendo creación"
      end
    rescue => e
      puts "Error al verificar memorials: #{e.message}"
    end
  else
    puts "El modelo Memorial no está definido o el usuario no tiene memorials"
  end

  # Crear órdenes y clientes si los modelos existen
  if defined?(Order) && defined?(Customer)
    begin
      puts "Verificando customers y orders..."
      
      # Crear un cliente
      begin
        customer = Customer.find_or_create_by!(email: "cliente@ejemplo.com") do |c|
          c.first_name = "Juan"
          c.last_name = "Pérez"
          c.phone = "1234567890"
          c.address = "Calle Principal 123"
          c.city = "Buenos Aires"
          c.province = "CABA"
          c.postal_code = "1001"
        end
        puts "Cliente creado o encontrado correctamente"
      rescue => e
        puts "Error al crear cliente: #{e.message}"
        customer = nil
      end
      
      # Verificar si ya existen órdenes para evitar duplicados
      if customer && Order.count == 0
        puts "Creando órdenes de ejemplo..."
        
        # Crear órdenes con diferentes estados
        statuses = ["pending", "completed", "rejected", "in_process"]
        membership_types = ["acompanandote", "recordandote", "siempre"]
        
        3.times do |i|
          begin
            order = Order.create!(
              uuid: SecureRandom.uuid,
              customer_id: customer.id,
              membership_type: membership_types.sample,
              amount: [12, 15, 18].sample,
              status: statuses.sample,
              payment_id: "TEST-#{SecureRandom.hex(10)}"
            )
            
            # Asegurar al menos una orden completada para pruebas
            if i == 0
              order.update_column(:status, "completed")
            end
            
            # Crear información de envío para órdenes completadas
            if order.status == "completed" && defined?(ShippingInfo)
              begin
                shipping = ShippingInfo.new(
                  order_id: order.id,
                  status: ["pending", "shipped"].sample
                )
                
                # Añadir información de seguimiento a algunas órdenes
                if rand > 0.5
                  shipping.tracking_code = "TRACK-#{SecureRandom.hex(6)}"
                  shipping.carrier_name = ["Correo Argentino", "OCA", "Andreani"].sample
                  shipping.shipped_date = Date.today - rand(5).days
                  shipping.estimated_delivery_date = Date.today + rand(10).days
                end
                
                shipping.save!
                puts "Información de envío creada para la orden #{order.id}"
              rescue => e
                puts "Error al crear shipping info: #{e.message}"
              end
            end
            
            # Crear membresía si el modelo existe
            if defined?(Membership)
              begin
                Membership.create!(
                  order_id: order.id,
                  customer_id: customer.id,
                  membership_type: order.membership_type,
                  status: order.status,
                  start_date: Date.today,
                  end_date: Date.today + 1.year
                )
                puts "Membresía creada para la orden #{order.id}"
              rescue => e
                puts "Error al crear membresía: #{e.message}"
              end
            end
            
            puts "Orden #{i+1} creada correctamente"
          rescue => e
            puts "Error al crear orden #{i+1}: #{e.message}"
          end
        end
        
        puts "Órdenes creadas con éxito"
      else
        puts "Ya existen órdenes o no se pudo crear el cliente, omitiendo creación"
      end
    rescue => e
      puts "Error general al procesar órdenes: #{e.message}"
    end
  else
    puts "Los modelos Order o Customer no están definidos"
  end
else
  puts "No se pudieron crear los usuarios básicos, omitiendo el resto del seed"
end

puts "Proceso de seed completado"