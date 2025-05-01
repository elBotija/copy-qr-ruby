if Rails.env.production?
  Rails.application.config.action_mailer.smtp_settings = {
    address:              ENV['SMTP_SERVER'] || 'smtp.gmail.com',
    port:                 ENV['SMTP_PORT'] || 587,
    domain:               ENV['SMTP_DOMAIN'] || 'quierorecordarte.com.ar',
    user_name:            ENV['SMTP_USERNAME'],
    password:             ENV['SMTP_PASSWORD'],
    authentication:       'plain',
    enable_starttls_auto: true
  }
  
  # URL por defecto para los enlaces en los correos
  Rails.application.config.action_mailer.default_url_options = { 
    host: ENV['APP_HOST'] || 'quierorecordarte.com.ar',
    protocol: 'https'
  }
end

# En desarrollo, usar letter_opener para ver los correos en el navegador
if Rails.env.development?
  Rails.application.config.action_mailer.delivery_method = :letter_opener
  Rails.application.config.action_mailer.default_url_options = { host: 'localhost:3000', protocol: 'http' }
end