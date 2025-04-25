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
