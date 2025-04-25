# frozen_string_literal: true

# Configuración de Mercado Pago
if Rails.env.development? || Rails.env.test?
  ENV['MP_ACCESS_TOKEN'] ||= 'APP_USR-3664805261955273-032621-c0316d60db47a0fdf814212f8d4c825b-1461279103' # Reemplazar por token de prueba
  ENV['MP_PUBLIC_KEY'] ||= 'APP_USR-b00061fc-8859-48a1-959c-b64bf7973071' # Reemplazar por public key de prueba
end

# Configurar URL de retorno para desarrollo
if Rails.env.development?
  ENV['FRONTEND_URL'] ||= 'http://localhost:5501'
  ENV['BACKEND_URL'] ||= 'https://a42c-2802-8010-8213-de00-ddbc-1d3-6273-b1a8.ngrok-free.app' #podemos usar ngrok
elsif Rails.env.production?
  ENV['FRONTEND_URL'] ||= 'https://tudominio.com'
  ENV['BACKEND_URL'] ||= 'https://api.tudominio.com'
end
