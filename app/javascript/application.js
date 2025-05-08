// Configure your import map in config/importmap.rb. Read more: https://github.com/rails/importmap-rails
import "@hotwired/turbo-rails"

import "@popperjs/core"
import "bootstrap"

window.copyToClipboard = function(text) {
  navigator.clipboard.writeText(text).then(function() {
    alert('URL copiada al portapapeles');
  }, function() {
    alert('No se pudo copiar la URL');
  });
}