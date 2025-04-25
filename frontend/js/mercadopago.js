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
