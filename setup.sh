#!/bin/bash

set -e # Exit immediately if a command exits with a non-zero status

# Colores para mensajes
GREEN='\033[0;32m'
BLUE='\033[0;34m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Banner
echo -e "${BLUE}"
echo "====================================================="
echo "        INSTALACIÓN DE MERCADO PAGO EN QUIERO        "
echo "                  RECORDARTE PROJECT                  "
echo "====================================================="
echo -e "${NC}"

# Función para mostrar mensajes con formato
function log_info() {
  echo -e "${GREEN}[INFO]${NC} $1"
}

function log_warning() {
  echo -e "${YELLOW}[WARNING]${NC} $1"
}

function log_error() {
  echo -e "${RED}[ERROR]${NC} $1"
  exit 1
}

function check_command() {
  if ! command -v $1 &> /dev/null; then
    log_error "$1 no está instalado. Por favor instálalo antes de continuar."
  fi
}

# Verifica prerrequisitos
log_info "Verificando prerrequisitos..."
check_command "ruby"
check_command "bundle"
check_command "rails"

# Verifica que estamos en la raíz del proyecto
if [ ! -f "Gemfile" ] || [ ! -d "app" ]; then
  log_error "El script debe ejecutarse desde la raíz del proyecto Rails."
fi

# Instalar gema de Mercado Pago
log_info "Agregando gema de Mercado Pago al Gemfile..."
if ! grep -q "gem 'mercadopago'" Gemfile; then
  echo "gem 'mercadopago', '~> 2.1.0'" >> Gemfile
  log_info "Gema mercadopago agregada al Gemfile."
else
  log_warning "La gema mercadopago ya está en el Gemfile."
fi

# Instalar dependencias
log_info "Instalando dependencias..."
bundle install || log_error "Error al instalar dependencias."

# Crear archivo de configuración para Mercado Pago
log_info "Creando archivo de configuración para Mercado Pago..."
mkdir -p config/initializers

cat > config/initializers/mercado_pago.rb << 'EOL'
# frozen_string_literal: true

# Configuración de Mercado Pago
if Rails.env.development? || Rails.env.test?
  ENV['MP_ACCESS_TOKEN'] ||= 'TEST-XXX' # Reemplazar por token de prueba
  ENV['MP_PUBLIC_KEY'] ||= 'TEST-XXX' # Reemplazar por public key de prueba
end

# Configurar URL de retorno para desarrollo
if Rails.env.development?
  ENV['FRONTEND_URL'] ||= 'http://localhost:5000'
  ENV['BACKEND_URL'] ||= 'http://localhost:3000'
elsif Rails.env.production?
  ENV['FRONTEND_URL'] ||= 'https://tudominio.com'
  ENV['BACKEND_URL'] ||= 'https://api.tudominio.com'
end
EOL

log_info "Archivo de configuración creado en config/initializers/mercado_pago.rb"

# Crear modelos necesarios
log_info "Creando modelos necesarios..."

# Modelo Order
rails g model Order uuid:string:uniq customer_id:integer membership_type:string amount:decimal status:string payment_id:string || log_error "Error al crear modelo Order."

# Modelo Customer
rails g model Customer first_name:string last_name:string email:string phone:string address:string city:string province:string postal_code:string || log_error "Error al crear modelo Customer."

# Modelo Membership
rails g model Membership order_id:references customer_id:references membership_type:string status:string start_date:datetime end_date:datetime || log_error "Error al crear modelo Membership."

# Crear controlador de Pagos
log_info "Creando controlador de Pagos..."

mkdir -p app/controllers/api/v1

cat > app/controllers/api/v1/payments_controller.rb << 'EOL'
# frozen_string_literal: true

module Api
  module V1
    class PaymentsController < ApplicationController
      require 'mercadopago'
      require 'securerandom'
      skip_before_action :verify_authenticity_token, only: [:webhook]

      # Acción para crear una preferencia de pago
      def create_preference
        # Obtiene los datos del formulario
        membership_type = params[:membershipType]
        first_name = params[:firstName]
        last_name = params[:lastName]
        email = params[:email]
        phone = params[:phone]
        address = params[:address]
        city = params[:city]
        province = params[:province]
        postal_code = params[:postalCode]
        
        # Genera un ID único para la orden
        order_id = SecureRandom.uuid
        
        # Obtiene los detalles de la membresía
        membership = get_membership_details(membership_type)
        
        # Crea la orden en la base de datos
        customer = Customer.create!(
          first_name: first_name,
          last_name: last_name,
          email: email,
          phone: phone,
          address: address,
          city: city,
          province: province,
          postal_code: postal_code
        )
        
        order = Order.create!(
          uuid: order_id,
          customer_id: customer.id,
          membership_type: membership_type,
          status: 'pending',
          amount: membership[:price]
        )
        
        # Configura el SDK de Mercado Pago
        sdk = Mercadopago::SDK.new(ENV['MP_ACCESS_TOKEN'])
        
        # Crea la preferencia
        preference_data = {
          items: [
            {
              id: membership_type,
              title: "Membresía #{membership[:name]}",
              description: "Membresía #{membership[:name]} - Quiero Recordarte",
              unit_price: membership[:price],
              quantity: 1,
              currency_id: "ARS"
            }
          ],
          payer: {
            name: first_name,
            surname: last_name,
            email: email,
            phone: {
              number: phone
            },
            address: {
              street_name: address,
              zip_code: postal_code
            }
          },
          # URLs de retorno después del pago
          back_urls: {
            success: "#{ENV['FRONTEND_URL']}/success?order_id=#{order_id}",
            failure: "#{ENV['FRONTEND_URL']}/failure?order_id=#{order_id}",
            pending: "#{ENV['FRONTEND_URL']}/pending?order_id=#{order_id}"
          },
          auto_return: "approved",
          # Referencia externa para asociar esta preferencia con tu orden
          external_reference: order_id,
          # Notificación de webhook
          notification_url: "#{ENV['BACKEND_URL']}/api/v1/webhook"
        }
        
        # Crea la preferencia en Mercado Pago
        preference_response = sdk.preference.create(preference_data)
        
        # Verifica la respuesta
        if preference_response[:status] == "201"
          # Devuelve los datos necesarios al frontend
          render json: {
            id: preference_response[:response]['id'],
            init_point: preference_response[:response]['init_point'],
            orderId: order_id
          }
        else
          # Maneja el error
          render json: { error: 'Error al crear la preferencia de pago' }, status: :unprocessable_entity
        end
      end
      
      # Acción para recibir webhooks de Mercado Pago
      def webhook
        # Verifica la autenticidad de la notificación
        if params[:type] == "payment"
          payment_id = params[:data][:id]
          
          # Configura el SDK de Mercado Pago
          sdk = Mercadopago::SDK.new(ENV['MP_ACCESS_TOKEN'])
          
          # Obtiene la información del pago
          payment_response = sdk.payment.get(payment_id)
          
          if payment_response[:status] == "200"
            payment_info = payment_response[:response]
            external_reference = payment_info['external_reference']
            status = payment_info['status']
            
            # Encuentra la orden correspondiente
            order = Order.find_by(uuid: external_reference)
            
            if order
              # Actualiza el estado de la orden según el estado del pago
              case status
              when "approved"
                order.update(status: "completed", payment_id: payment_id)
                # Activa la membresía
                activate_membership(order)
                # Envía email de confirmación
                # PaymentMailer.payment_approved(order).deliver_later
              when "rejected"
                order.update(status: "rejected", payment_id: payment_id)
                # PaymentMailer.payment_rejected(order).deliver_later
              when "pending"
                order.update(status: "pending", payment_id: payment_id)
                # PaymentMailer.payment_pending(order).deliver_later
              when "in_process"
                order.update(status: "in_process", payment_id: payment_id)
              when "refunded"
                order.update(status: "refunded", payment_id: payment_id)
                # PaymentMailer.payment_refunded(order).deliver_later
              end
            end
          end
        end
        
        # Siempre responde con 200 OK para confirmar la recepción
        head :ok
      end
      
      # Acción para obtener el estado de una orden
      def order_status
        order = Order.find_by(uuid: params[:id])
        
        if order
          render json: {
            id: order.uuid,
            status: order.status,
            membership_type: order.membership_type,
            created_at: order.created_at
          }
        else
          render json: { error: 'Orden no encontrada' }, status: :not_found
        end
      end
      
      private
      
      # Método para obtener detalles de la membresía
      def get_membership_details(membership_type)
        memberships = {
          'acompanandote' => {
            name: 'Acompañandote',
            price: 120000,
          },
          'recordandote' => {
            name: 'Recordandote',
            price: 150000,
          },
          'siempre' => {
            name: 'Siempre Juntos',
            price: 180000,
          }
        }
        
        memberships[membership_type] || memberships['acompanandote']
      end
      
      # Método para activar la membresía
      def activate_membership(order)
        # Implementa la lógica para activar la membresía
        # Por ejemplo, crear un registro en una tabla de membresías activas
        Membership.create!(
          order_id: order.id,
          customer_id: order.customer_id,
          membership_type: order.membership_type,
          status: 'active',
          start_date: Time.current,
          end_date: Time.current + 1.year # Asumiendo que la membresía dura 1 año
        )
      end
    end
  end
end
EOL

log_info "Controlador de pagos creado en app/controllers/api/v1/payments_controller.rb"

# Actualizar rutas para incluir el controlador de pagos
log_info "Actualizando rutas..."

cat > config/routes.rb << 'EOL'
Rails.application.routes.draw do
  resources :memorials, only: %i[new create show edit update]

  devise_for :users
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => 'rails/health#show', as: :rails_health_check

  namespace :admin do
    resources :promo, only: %i[index show create]
    resources :qr_codes, only: %i[new create]

    root 'dashboard#index'
  end

  # API para pagos
  namespace :api do
    namespace :v1 do
      post '/create-preference', to: 'payments#create_preference'
      post '/webhook', to: 'payments#webhook'
      get '/orders/:id', to: 'payments#order_status'
    end
  end

  # Defines the root path route ("/")
  root 'home#index'
end
EOL

log_info "Rutas actualizadas en config/routes.rb"

# Crear archivos necesarios en frontend
log_info "Creando archivos para el frontend..."

mkdir -p frontend
mkdir -p frontend/js
mkdir -p frontend/css
mkdir -p frontend/pages

# Crear archivo para la integración de Mercado Pago en el frontend
cat > frontend/js/mercadopago.js << 'EOL'
// Integración con Mercado Pago

// Función para crear una preferencia de pago
async function createPaymentPreference(formData) {
  try {
    const response = await fetch(`${API_URL}/api/v1/create-preference`, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
      },
      body: JSON.stringify(formData)
    });

    if (!response.ok) {
      const errorData = await response.json();
      throw new Error(errorData.error || 'Error al crear la preferencia de pago');
    }

    return await response.json();
  } catch (error) {
    console.error('Error:', error);
    throw error;
  }
}

// Función para obtener el estado de una orden
async function getOrderStatus(orderId) {
  try {
    const response = await fetch(`${API_URL}/api/v1/orders/${orderId}`);
    
    if (!response.ok) {
      const errorData = await response.json();
      throw new Error(errorData.error || 'Error al obtener el estado de la orden');
    }

    return await response.json();
  } catch (error) {
    console.error('Error:', error);
    throw error;
  }
}

// Función principal para iniciar el proceso de pago
async function initPayment(formData) {
  try {
    // Mostrar indicador de carga
    showLoading(true);
    
    // Crear preferencia de pago
    const preferenceData = await createPaymentPreference(formData);
    
    // Guardar ID de orden en localStorage para referencia posterior
    localStorage.setItem('currentOrderId', preferenceData.orderId);
    
    // Redirigir al usuario a la página de pago de Mercado Pago
    window.location.href = preferenceData.init_point;
    
  } catch (error) {
    // Mostrar mensaje de error
    showError('Error al procesar el pago: ' + error.message);
    showLoading(false);
  }
}

// Función para manejar el estado después del pago
function handlePaymentStatus() {
  const urlParams = new URLSearchParams(window.location.search);
  const orderId = urlParams.get('order_id');
  
  if (orderId) {
    showLoading(true);
    
    getOrderStatus(orderId)
      .then(orderData => {
        // Actualizar la interfaz según el estado del pago
        updatePaymentStatusUI(orderData.status, orderData);
      })
      .catch(error => {
        showError('Error al verificar el estado del pago: ' + error.message);
      })
      .finally(() => {
        showLoading(false);
      });
  }
}

// Función auxiliar para mostrar/ocultar indicador de carga
function showLoading(show) {
  const loadingElement = document.getElementById('loading-indicator');
  if (loadingElement) {
    loadingElement.style.display = show ? 'flex' : 'none';
  }
}

// Función auxiliar para mostrar mensajes de error
function showError(message) {
  const errorElement = document.getElementById('error-message');
  if (errorElement) {
    errorElement.textContent = message;
    errorElement.style.display = 'block';
  }
  console.error(message);
}

// Función para actualizar la interfaz según el estado del pago
function updatePaymentStatusUI(status, orderData) {
  const statusContainerElement = document.getElementById('payment-status-container');
  const statusTitleElement = document.getElementById('payment-status-title');
  const statusMessageElement = document.getElementById('payment-status-message');
  
  if (!statusContainerElement || !statusTitleElement || !statusMessageElement) {
    return;
  }
  
  statusContainerElement.style.display = 'block';
  
  switch (status) {
    case 'completed':
      statusContainerElement.className = 'status-success';
      statusTitleElement.textContent = '¡Pago Completado!';
      statusMessageElement.textContent = 'Tu pago ha sido procesado exitosamente. ¡Gracias por tu compra!';
      break;
    case 'pending':
      statusContainerElement.className = 'status-pending';
      statusTitleElement.textContent = 'Pago Pendiente';
      statusMessageElement.textContent = 'Tu pago está siendo procesado. Te notificaremos cuando se complete.';
      break;
    case 'rejected':
      statusContainerElement.className = 'status-error';
      statusTitleElement.textContent = 'Pago Rechazado';
      statusMessageElement.textContent = 'Lo sentimos, tu pago fue rechazado. Por favor intenta con otro método de pago.';
      break;
    case 'refunded':
      statusContainerElement.className = 'status-info';
      statusTitleElement.textContent = 'Pago Reembolsado';
      statusMessageElement.textContent = 'Tu pago ha sido reembolsado.';
      break;
    default:
      statusContainerElement.className = 'status-info';
      statusTitleElement.textContent = 'Estado del Pago';
      statusMessageElement.textContent = `Estado actual: ${status}`;
  }
}

// Exportar funciones para uso en otros archivos
window.MPCheckout = {
  initPayment,
  handlePaymentStatus,
  getOrderStatus
};
EOL

log_info "Archivo de integración de Mercado Pago creado en frontend/js/mercadopago.js"

# Crear páginas de resultado para el frontend
cat > frontend/pages/success.html << 'EOL'
<!DOCTYPE html>
<html lang="es">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>Pago Exitoso - Quiero Recordarte</title>
  <script src="https://cdn.tailwindcss.com"></script>
  <link rel="stylesheet" href="../css/styles.css">
</head>
<body class="bg-gray-100 min-h-screen">
  <div class="container mx-auto px-4 py-16">
    <div class="max-w-md mx-auto bg-white rounded-lg shadow-lg overflow-hidden">
      <div class="p-8 text-center">
        <div class="mx-auto w-24 h-24 bg-green-100 rounded-full flex items-center justify-center mb-6">
          <svg xmlns="http://www.w3.org/2000/svg" class="h-12 w-12 text-green-500" fill="none" viewBox="0 0 24 24" stroke="currentColor">
            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M5 13l4 4L19 7" />
          </svg>
        </div>
        
        <h1 class="text-2xl font-bold text-gray-800 mb-2">¡Pago Exitoso!</h1>
        <p class="text-gray-600 mb-6">Tu pago ha sido procesado correctamente. ¡Gracias por tu compra!</p>
        
        <div id="payment-details" class="mb-8 text-left bg-gray-50 p-4 rounded-lg">
          <p class="text-sm text-gray-600 mb-2"><strong>ID de Orden:</strong> <span id="order-id"></span></p>
          <p class="text-sm text-gray-600 mb-2"><strong>Estado:</strong> <span id="order-status"></span></p>
          <p class="text-sm text-gray-600 mb-2"><strong>Membresía:</strong> <span id="membership-type"></span></p>
          <p class="text-sm text-gray-600"><strong>Fecha:</strong> <span id="order-date"></span></p>
        </div>
        
        <div class="space-y-3">
          <a href="/" class="block w-full bg-[#00524b] text-white px-4 py-2 rounded font-semibold hover:bg-[#003d38] transition-colors">
            Volver al Inicio
          </a>
          <button type="button" class="block w-full bg-gray-200 text-gray-700 px-4 py-2 rounded font-semibold hover:bg-gray-300 transition-colors" onclick="window.print()">
            Imprimir Comprobante
          </button>
        </div>
      </div>
    </div>
  </div>

  <!-- Loading indicator -->
  <div id="loading-indicator" class="fixed inset-0 bg-black bg-opacity-50 flex items-center justify-center z-50" style="display: none;">
    <div class="bg-white p-5 rounded-lg">
      <svg class="animate-spin h-10 w-10 text-[#00524b] mx-auto" xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24">
        <circle class="opacity-25" cx="12" cy="12" r="10" stroke="currentColor" stroke-width="4"></circle>
        <path class="opacity-75" fill="currentColor" d="M4 12a8 8 0 018-8V0C5.373 0 0 5.373 0 12h4zm2 5.291A7.962 7.962 0 014 12H0c0 3.042 1.135 5.824 3 7.938l3-2.647z"></path>
      </svg>
      <p class="mt-2 text-center">Cargando información del pago...</p>
    </div>
  </div>

  <!-- Error message -->
  <div id="error-message" class="fixed bottom-4 right-4 bg-red-500 text-white p-4 rounded-lg shadow-lg" style="display: none;"></div>

  <script>
    // Configuración global
    const API_URL = 'http://localhost:3000'; // Cambiar a tu URL de producción en producción
  </script>
  <script src="../js/mercadopago.js"></script>
  <script>
    document.addEventListener('DOMContentLoaded', () => {
      // Obtener ID de orden de los parámetros URL
      const urlParams = new URLSearchParams(window.location.search);
      const orderId = urlParams.get('order_id');
      
      if (orderId) {
        document.getElementById('order-id').textContent = orderId;
        
        // Cargar detalles de la orden
        window.MPCheckout.getOrderStatus(orderId)
          .then(orderData => {
            document.getElementById('order-status').textContent = orderData.status === 'completed' ? 'Completado' : orderData.status;
            document.getElementById('membership-type').textContent = orderData.membership_type || 'No disponible';
            document.getElementById('order-date').textContent = new Date(orderData.created_at).toLocaleString();
          })
          .catch(error => {
            console.error('Error al cargar detalles de la orden:', error);
          });
      } else {
        document.getElementById('payment-details').innerHTML = '<p class="text-red-500">No se pudo obtener información del pago.</p>';
      }
    });
  </script>
</body>
</html>
EOL

log_info "Página de éxito de pago creada en frontend/pages/success.html"

# Crear página de error
cat > frontend/pages/failure.html << 'EOL'
<!DOCTYPE html>
<html lang="es">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>Pago Fallido - Quiero Recordarte</title>
  <script src="https://cdn.tailwindcss.com"></script>
  <link rel="stylesheet" href="../css/styles.css">
</head>
<body class="bg-gray-100 min-h-screen">
  <div class="container mx-auto px-4 py-16">
    <div class="max-w-md mx-auto bg-white rounded-lg shadow-lg overflow-hidden">
      <div class="p-8 text-center">
        <div class="mx-auto w-24 h-24 bg-red-100 rounded-full flex items-center justify-center mb-6">
          <svg xmlns="http://www.w3.org/2000/svg" class="h-12 w-12 text-red-500" fill="none" viewBox="0 0 24 24" stroke="currentColor">
            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M6 18L18 6M6 6l12 12" />
          </svg>
        </div>
        
        <h1 class="text-2xl font-bold text-gray-800 mb-2">Pago Fallido</h1>
        <p class="text-gray-600 mb-6">Lo sentimos, hubo un problema al procesar tu pago.</p>
        
        <div id="payment-details" class="mb-8 text-left bg-gray-50 p-4 rounded-lg">
          <p class="text-sm text-gray-600 mb-2"><strong>ID de Orden:</strong> <span id="order-id"></span></p>
          <p class="text-sm text-gray-600 mb-2"><strong>Estado:</strong> <span id="order-status"></span></p>
          <p class="text-sm text-gray-600 mb-2"><strong>Membresía:</strong> <span id="membership-type"></span></p>
          <p class="text-sm text-gray-600"><strong>Fecha:</strong> <span id="order-date"></span></p>
        </div>
        
        <div class="space-y-3">
          <a href="/" class="block w-full bg-[#00524b] text-white px-4 py-2 rounded font-semibold hover:bg-[#003d38] transition-colors">
            Volver al Inicio
          </a>
          <a href="/checkout.html" class="block w-full bg-gray-200 text-gray-700 px-4 py-2 rounded font-semibold hover:bg-gray-300 transition-colors">
            Intentar de Nuevo
          </a>
        </div>
      </div>
    </div>
  </div>

  <!-- Loading indicator -->
  <div id="loading-indicator" class="fixed inset-0 bg-black bg-opacity-50 flex items-center justify-center z-50" style="display: none;">
    <div class="bg-white p-5 rounded-lg">
      <svg class="animate-spin h-10 w-10 text-[#00524b] mx-auto" xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24">
        <circle class="opacity-25" cx="12" cy="12" r="10" stroke="currentColor" stroke-width="4"></circle>
        <path class="opacity-75" fill="currentColor" d="M4 12a8 8 0 018-8V0C5.373 0 0 5.373 0 12h4zm2 5.291A7.962 7.962 0 014 12H0c0 3.042 1.135 5.824 3 7.938l3-2.647z"></path>
      </svg>
      <p class="mt-2 text-center">Cargando información del pago...</p>
    </div>
  </div>

  <!-- Error message -->
  <div id="error-message" class="fixed bottom-4 right-4 bg-red-500 text-white p-4 rounded-lg shadow-lg" style="display: none;"></div>

  <script>
    // Configuración global
    const API_URL = 'http://localhost:3000'; // Cambiar a tu URL de producción en producción
  </script>
  <script src="../js/mercadopago.js"></script>
  <script>
    document.addEventListener('DOMContentLoaded', () => {
      // Obtener ID de orden de los parámetros URL
      const urlParams = new URLSearchParams(window.location.search);
      const orderId = urlParams.get('order_id');
      
      if (orderId) {
        document.getElementById('order-id').textContent = orderId;
        
        // Cargar detalles de la orden
        window.MPCheckout.getOrderStatus(orderId)
          .then(orderData => {
            document.getElementById('order-status').textContent = orderData.status === 'rejected' ? 'Rechazado' : orderData.status;
            document.getElementById('membership-type').textContent = orderData.membership_type || 'No disponible';
            document.getElementById('order-date').textContent = new Date(orderData.created_at).toLocaleString();
          })
          .catch(error => {
            console.error('Error al cargar detalles de la orden:', error);
          });
      } else {
        document.getElementById('payment-details').innerHTML = '<p class="text-red-500">No se pudo obtener información del pago.</p>';
      }
    });
  </script>
</body>
</html>
EOL

log_info "Página de fallo de pago creada en frontend/pages/failure.html"

# Crear página de pago pendiente
cat > frontend/pages/pending.html << 'EOL'
<!DOCTYPE html>
<html lang="es">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>Pago Pendiente - Quiero Recordarte</title>
  <script src="https://cdn.tailwindcss.com"></script>
  <link rel="stylesheet" href="../css/styles.css">
</head>
<body class="bg-gray-100 min-h-screen">
  <div class="container mx-auto px-4 py-16">
    <div class="max-w-md mx-auto bg-white rounded-lg shadow-lg overflow-hidden">
      <div class="p-8 text-center">
        <div class="mx-auto w-24 h-24 bg-yellow-100 rounded-full flex items-center justify-center mb-6">
          <svg xmlns="http://www.w3.org/2000/svg" class="h-12 w-12 text-yellow-500" fill="none" viewBox="0 0 24 24" stroke="currentColor">
            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 8v4l3 3m6-3a9 9 0 11-18 0 9 9 0 0118 0z" />
          </svg>
        </div>
        
        <h1 class="text-2xl font-bold text-gray-800 mb-2">Pago Pendiente</h1>
        <p class="text-gray-600 mb-6">Tu pago está siendo procesado. Te notificaremos cuando se complete.</p>
        
        <div id="payment-details" class="mb-8 text-left bg-gray-50 p-4 rounded-lg">
          <p class="text-sm text-gray-600 mb-2"><strong>ID de Orden:</strong> <span id="order-id"></span></p>
          <p class="text-sm text-gray-600 mb-2"><strong>Estado:</strong> <span id="order-status"></span></p>
          <p class="text-sm text-gray-600 mb-2"><strong>Membresía:</strong> <span id="membership-type"></span></p>
          <p class="text-sm text-gray-600"><strong>Fecha:</strong> <span id="order-date"></span></p>
        </div>
        
        <div class="space-y-3">
          <a href="/" class="block w-full bg-[#00524b] text-white px-4 py-2 rounded font-semibold hover:bg-[#003d38] transition-colors">
            Volver al Inicio
          </a>
          <button type="button" class="block w-full bg-gray-200 text-gray-700 px-4 py-2 rounded font-semibold hover:bg-gray-300 transition-colors" onclick="window.print()">
            Imprimir Comprobante
          </button>
        </div>
      </div>
    </div>
  </div>

  <!-- Loading indicator -->
  <div id="loading-indicator" class="fixed inset-0 bg-black bg-opacity-50 flex items-center justify-center z-50" style="display: none;">
    <div class="bg-white p-5 rounded-lg">
      <svg class="animate-spin h-10 w-10 text-[#00524b] mx-auto" xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24">
        <circle class="opacity-25" cx="12" cy="12" r="10" stroke="currentColor" stroke-width="4"></circle>
        <path class="opacity-75" fill="currentColor" d="M4 12a8 8 0 018-8V0C5.373 0 0 5.373 0 12h4zm2 5.291A7.962 7.962 0 014 12H0c0 3.042 1.135 5.824 3 7.938l3-2.647z"></path>
      </svg>
      <p class="mt-2 text-center">Cargando información del pago...</p>
    </div>
  </div>

  <!-- Error message -->
  <div id="error-message" class="fixed bottom-4 right-4 bg-red-500 text-white p-4 rounded-lg shadow-lg" style="display: none;"></div>

  <script>
    // Configuración global
    const API_URL = 'http://localhost:3000'; // Cambiar a tu URL de producción en producción
  </script>
  <script src="../js/mercadopago.js"></script>
  <script>
    document.addEventListener('DOMContentLoaded', () => {
      // Obtener ID de orden de los parámetros URL
      const urlParams = new URLSearchParams(window.location.search);
      const orderId = urlParams.get('order_id');
      
      if (orderId) {
        document.getElementById('order-id').textContent = orderId;
        
        // Cargar detalles de la orden
        window.MPCheckout.getOrderStatus(orderId)
          .then(orderData => {
            document.getElementById('order-status').textContent = orderData.status === 'pending' ? 'Pendiente' : orderData.status;
            document.getElementById('membership-type').textContent = orderData.membership_type || 'No disponible';
            document.getElementById('order-date').textContent = new Date(orderData.created_at).toLocaleString();
          })
          .catch(error => {
            console.error('Error al cargar detalles de la orden:', error);
          });
      } else {
        document.getElementById('payment-details').innerHTML = '<p class="text-red-500">No se pudo obtener información del pago.</p>';
      }
    });
  </script>
</body>
</html>
EOL

log_info "Página de pago pendiente creada en frontend/pages/pending.html"

# Actualizar el script de checkout existente
log_info "Actualizando script de checkout..."

# Backup del archivo existente de checkout
if [ -f "frontend/js/checkout.js" ]; then
  cp frontend/js/checkout.js frontend/js/checkout.js.bak
  log_info "Se ha creado una copia de seguridad del script de checkout en frontend/js/checkout.js.bak"
fi

cat > frontend/js/checkout.js << 'EOL'
// Script de checkout con integración de Mercado Pago

$(document).ready(function() {
  // Configuración global
  const API_URL = 'http://localhost:3000'; // Cambiar a tu URL de producción en producción
  
  // ... tu código existente de checkout ...
  
  // Modificar el manejo del formulario
  $('#checkoutForm').on('submit', function(e) {
    e.preventDefault();
    
    if (validateStep(currentStep)) {
      try {
        // Mostrar un indicador de carga
        showLoading(true);
        
        // Recopilar los datos del formulario
        const formData = {
          membershipType: membershipType,
          firstName: $('#firstName').val(),
          lastName: $('#lastName').val(),
          email: $('#email').val(),
          phone: $('#phone').val(),
          address: $('#address').val(),
          city: $('#city').val(),
          province: $('#province').val(),
          postalCode: $('#postalCode').val()
        };
        
        // Iniciar proceso de pago con Mercado Pago
        window.MPCheckout.initPayment(formData);
      } catch (error) {
        console.error('Error:', error);
        alert('Ocurrió un error inesperado. Por favor intenta nuevamente.');
        showLoading(false);
      }
    }
  });
  
  // Función para mostrar/ocultar indicador de carga
  function showLoading(show) {
    if (show) {
      // Mostrar indicador de carga
      $('button[type="submit"]').prop('disabled', true).html('<i class="fas fa-spinner fa-spin mr-2"></i>Procesando...');
    } else {
      // Ocultar indicador de carga
      $('button[type="submit"]').prop('disabled', false).html('Finalizar Compra');
    }
  }
});
EOL

log_info "Script de checkout actualizado en frontend/js/checkout.js"

# Modificar el archivo de checkout HTML para incluir el script de Mercado Pago
log_info "Buscando archivo de checkout HTML para actualizar..."

# Buscar el archivo de checkout en la raíz del proyecto y directorios comunes
checkout_files=(
  "./checkout.html"
  "./public/checkout.html"
  "./frontend/checkout.html"
  "./public/frontend/checkout.html"
)

checkout_found=false
for file in "${checkout_files[@]}"; do
  if [ -f "$file" ]; then
    log_info "Encontrado archivo de checkout en $file"
    checkout_found=true
    
    # Hacer backup
    cp "$file" "${file}.bak"
    log_info "Se ha creado una copia de seguridad del archivo de checkout en ${file}.bak"
    
    # Agregar el script de Mercado Pago antes del cierre de </body>
    sed -i 's|</body>|  <script src="js/mercadopago.js"></script>\n</body>|' "$file"
    log_info "Se ha actualizado el archivo de checkout para incluir el script de Mercado Pago"
    break
  fi
done

if [ "$checkout_found" = false ]; then
  log_warning "No se encontró el archivo de checkout HTML. Asegúrate de agregar manualmente el script de Mercado Pago a tu página de checkout."
fi

# Ejecutar migraciones en Docker
log_info "Ejecutando migraciones en Docker..."

# Ejecutar migración
docker compose exec app bundle exec bin/rails db:migrate

# Si hay error en la migración, intentar crear la base de datos primero
if [ $? -ne 0 ]; then
  log_warning "Error al ejecutar migraciones. Intentando crear la base de datos primero..."
  docker compose exec app bundle exec bin/rails db:create
  docker compose exec app bundle exec bin/rails db:migrate
fi

# Reiniciar la aplicación Docker
log_info "Reiniciando la aplicación en Docker..."
docker compose restart app

log_info "¡Integración de Mercado Pago completada!"
log_info "Para finalizar la configuración:"
log_info "1. Actualiza tus credenciales de Mercado Pago en config/initializers/mercado_pago.rb"
log_info "2. Actualiza las URLs de retorno en frontend/js/mercadopago.js"
log_info "3. Asegúrate de que los puertos y dominios estén correctamente configurados para desarrollo y producción"

# Instrucciones finales
cat << EOL

=====================================================================
                        ¡IMPORTANTE!
=====================================================================

Para completar la configuración de Mercado Pago:

1. Obtén tus credenciales en https://www.mercadopago.com.ar/developers/panel/credentials

2. Actualiza tus credenciales ejecutando:
   $ docker compose exec app /bin/bash -c 'echo "ENV['"'"'MP_ACCESS_TOKEN'"'"']='"'"'TU-ACCESS-TOKEN'"'"'" >> .env'
   $ docker compose exec app /bin/bash -c 'echo "ENV['"'"'MP_PUBLIC_KEY'"'"']='"'"'TU-PUBLIC-KEY'"'"'" >> .env'

3. Configura tus URLs de retorno:
   $ docker compose exec app /bin/bash -c 'echo "ENV['"'"'FRONTEND_URL'"'"']='"'"'http://tudominio.com'"'"'" >> .env'
   $ docker compose exec app /bin/bash -c 'echo "ENV['"'"'BACKEND_URL'"'"']='"'"'http://api.tudominio.com'"'"'" >> .env'

4. Reinicia tu aplicación:
   $ docker compose restart app

5. Para probar en desarrollo, usa estas tarjetas de prueba:
   - VISA: 4509 9535 6623 3704, CVV: 123, Fecha: 11/25
   - MASTERCARD: 5031 7557 3453 0604, CVV: 123, Fecha: 11/25
   - Para aprobación: Cualquier documento
   - Para rechazo: Documento 12345678

=====================================================================

EOL

exit 0
    });
