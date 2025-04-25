async function generateAndSaveCampaign() {
  const campaignData = {
    campaign: {
      name: document.getElementById('campaign-name').value,
      utm_campaign: document.getElementById('utm-campaign').value,
      qr_count: parseInt(document.getElementById('qrCount').value),
      start_date: document.getElementById('start-date').value,
      end_date: document.getElementById('end-date').value,
      active: true
    }
  };

  try {
    const response = await fetch('/admin/promo', {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'X-CSRF-Token': document.querySelector("[name='csrf-token']").content
      },
      body: JSON.stringify(campaignData)
    });

    if (!response.ok) {
      throw new Error('Error al guardar la campaña, no se puede repetir el tag UTM');
    }

    const data = await response.json();
    // prevent generate qrs
    // generateQRCodes();
    // Recargar la página para mostrar la nueva campaña
    window.location.reload();
  } catch (error) {
    console.error('Error:', error);
    alert('Error al crear la campaña: ' + error.message);
  }
}

function generateQRCode(url, elementId) {
  QRCode.toCanvas(document.getElementById(elementId), url, {
    errorCorrectionLevel: 'H',
    width: 256,
    margin: 1,
  }, function (error) {
    if (error) console.error(error);
    addLogoToQR(elementId);
  });
}

function addLogoToQR(canvasId) {
  const wrapper = document.getElementById(canvasId).parentElement;
  const logo = document.createElement('img');
  logo.src = '/assets/logo-imp2.png';
  logo.className = 'qr-logo';
  wrapper.appendChild(logo);
}

function generateQRCodes(campaign) {
  const container = document.getElementById('qrs-container');
  const qrCount = parseInt(campaign.qr_count) || 12;
  
  container.innerHTML = '';
  
  for (let i = 0; i < qrCount; i++) {
    const utmParams = new URLSearchParams({
      utm_campaign: campaign.utm_campaign,
      utm_source: 'qr_promocional',
      utm_medium: 'offline'
    });

    const finalUrl = `${campaign.base_url}/?${utmParams.toString()}`;
    
    const pWrapper = document.createElement('div');
    pWrapper.className = 'qr-container-wrapper';
    
    const wrapper = document.createElement('div');
    wrapper.className = 'qr-container';
    
    const canvasId = `qr-${i}`;
    const canvas = document.createElement('canvas');
    canvas.id = canvasId;
    
    wrapper.appendChild(canvas);
    pWrapper.appendChild(wrapper);
    
    const footer = document.createElement('div');
    footer.className = 'qr-footer';
    footer.innerHTML = "Quiero recordarte";
    pWrapper.appendChild(footer);

    container.appendChild(pWrapper);
    generateQRCode(finalUrl, canvasId);
  }
  setTimeout(() => {
    window.print();
  },1000);
}

async function regenerateQRs(campaignId) {
  try {
    const response = await fetch(`/admin/promo/${campaignId}`);
    const campaign = await response.json();
    // Generar los QRs
    generateQRCodes(campaign);
  } catch (error) {
    console.error('Error:', error);
    alert('Error al regenerar QRs');
  }
}


