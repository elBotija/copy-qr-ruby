# frozen_string_literal: true

# Configuración de Mercado Pago
if Rails.env.development? || Rails.env.test?
  ENV['MP_ACCESS_TOKEN'] ||= 'APP_USR-3664805261955273-032621-c0316d60db47a0fdf814212f8d4c825b-1461279103' # Reemplazar por token de prueba
  ENV['MP_PUBLIC_KEY'] ||= 'APP_USR-b00061fc-8859-48a1-959c-b64bf7973071' # Reemplazar por public key de prueba
end

# Configurar URL de retorno para desarrollo
if Rails.env.development?
  ENV['FRONTEND_URL'] ||= 'https://elbotija.github.io/preview'
  ENV['BACKEND_URL'] ||= 'https://9d4d-190-173-170-143.ngrok-free.app' #podemos usar ngrok
elsif Rails.env.production?
  ENV['FRONTEND_URL'] ||= 'https://tudominio.com'
  ENV['BACKEND_URL'] ||= 'https://api.tudominio.com'
end
