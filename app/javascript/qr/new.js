// Constantes de medidas en cm
const A4_WIDTH = 21;
const A4_HEIGHT = 29.7;
const QR_WIDTH = 4.87;
const QR_HEIGHT = 5.7;
const SEPARATION = 0.3;

// Calcular cuántos QRs caben por página
const qrsPerRow = Math.floor(A4_WIDTH / (QR_WIDTH + SEPARATION));
const qrsPerColumn = Math.floor(A4_HEIGHT / (QR_HEIGHT + SEPARATION));
const qrsPerPage = qrsPerRow * qrsPerColumn;

async function createQRCodes(count, membershipType) {
  try {
    const response = await fetch('/admin/qr_codes', {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'X-CSRF-Token': document.querySelector("[name='csrf-token']").content
      },
      body: JSON.stringify({
        count: count,
        membership_type: membershipType
      })
    });

    if (!response.ok) {
      throw new Error('Network response was not ok');
    }

    const data = await response.json();
    return data.qr_codes;
  } catch (error) {
    console.error('Error:', error);
    return [];
  }
}

function addLogoToQR(canvasId) {
  const canvas = document.getElementById(canvasId);
  if (!canvas) {
    console.error('Canvas no encontrado:', canvasId);
    return;
  }
  
  const qrContainer = canvas.parentElement;
  const logo = document.createElement('img');
  logo.src = '/assets/logo-imp2.png';
  logo.className = 'qr-logo';
  logo.onerror = function() {
    console.warn('No se pudo cargar el logo');
  };
  qrContainer.appendChild(logo);
}

function generateQRCode(url, elementId) {
  const canvasElement = document.getElementById(elementId);
  if (!canvasElement) {
    console.error('Canvas no encontrado:', elementId);
    return;
  }

  QRCode.toCanvas(canvasElement, url, {
    errorCorrectionLevel: 'H',
    width: 150,
    margin: 1,
  }, function (error) {
    if (error) {
      console.error('Error generando QR:', error);
    } else {
      console.log('QR generado para:', url);
      addLogoToQR(elementId);
    }
  });
}

async function generateQRCodes() {
  // Obtener valores de los controles
  const qrCount = parseInt(document.getElementById('qrCount').value) || 12;
  const membershipType = document.getElementById('membership').value;
  const footerText = "Quiero recordarte";
  
  // Limpiar contenedor existente
  const printArea = document.getElementById('qrs-container');
  printArea.innerHTML = '';
  
  // Obtener los códigos QR del backend
  const qrCodes = await createQRCodes(qrCount, membershipType);
  
  if (!qrCodes || qrCodes.length === 0) {
    console.error('No se pudieron obtener códigos QR');
    return;
  }
  
  // Calcular número de páginas necesarias
  const totalQRs = qrCodes.length;
  const totalPages = Math.ceil(totalQRs / qrsPerPage);
  
  // Fase 1: Crear todas las páginas
  const pages = [];
  for (let page = 0; page < totalPages; page++) {
    const pageContainer = document.createElement('div');
    pageContainer.className = 'print-container';
    printArea.appendChild(pageContainer);
    pages.push(pageContainer);
  }
  
  // Fase 2: Crear todos los contenedores de QR y agregarlos a las páginas
  const qrData = [];
  let qrCounter = 0;
  
  for (let page = 0; page < totalPages; page++) {
    const pageContainer = pages[page];
    const qrsThisPage = Math.min(qrsPerPage, totalQRs - qrCounter);
    
    // Calcular el offset para centrar
    const totalWidthUsed = qrsPerRow * QR_WIDTH + (qrsPerRow - 1) * SEPARATION;
    const totalHeightUsed = qrsPerColumn * QR_HEIGHT + (qrsPerColumn - 1) * SEPARATION;
    const horizontalOffset = (A4_WIDTH - totalWidthUsed) / 2;
    const verticalOffset = (A4_HEIGHT - totalHeightUsed) / 2;
    
    for (let i = 0; i < qrsThisPage; i++) {
      if (qrCounter >= totalQRs) break;
      
      // Obtener el código QR actual
      const qrCode = qrCodes[qrCounter];
      
      // Calcular posición en la grilla
      const row = Math.floor(i / qrsPerRow);
      const col = i % qrsPerRow;
      
      const canvasId = `qr-${page}-${i}`;
      
      // Crear el wrapper y posicionarlo
      const qrWrapper = document.createElement('div');
      qrWrapper.className = 'qr-wrapper';
      const left = horizontalOffset + col * (QR_WIDTH + SEPARATION);
      const top = verticalOffset + row * (QR_HEIGHT + SEPARATION);
      qrWrapper.style.left = `${left}cm`;
      qrWrapper.style.top = `${top}cm`;
      
      // Crear el contenedor del QR
      const qrContainer = document.createElement('div');
      qrContainer.className = 'qr-container';
      
      // Crear el canvas para el QR
      const canvas = document.createElement('canvas');
      canvas.id = canvasId;
      qrContainer.appendChild(canvas);
      
      // Crear el footer
      const footer = document.createElement('div');
      footer.className = 'qr-footer';
      footer.textContent = footerText;
      
      // Crear label para debug
      const label = document.createElement('div');
      label.className = 'qr-label';
      label.textContent = qrCode.code;
      
      // Armar la estructura
      qrWrapper.appendChild(qrContainer);
      qrWrapper.appendChild(footer);
      qrWrapper.appendChild(label);
      
      // Agregar al DOM
      pageContainer.appendChild(qrWrapper);
      
      // Guardar datos para generar QR después
      qrData.push({
        url: "https://app.quierorecordarte.com.ar/memorial/" + qrCode.code,
        canvasId: canvasId
      });
      
      qrCounter++;
    }
  }
  
  // Fase 3: Generar los QR después de que todo esté en el DOM
  // Pequeño retraso para asegurar que el DOM se ha actualizado
  setTimeout(() => {
    qrData.forEach(item => {
      generateQRCode(item.url, item.canvasId);
    });
  }, 50);
}