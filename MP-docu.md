# Documentación: Implementación de Mercado Pago en Quiero Recordarte

## Índice
1. [Descripción General](#descripción-general)
2. [Requisitos Previos](#requisitos-previos)
3. [Estructura de la Implementación](#estructura-de-la-implementación)
4. [Instalación](#instalación)
5. [Configuración](#configuración)
6. [Flujo de Pagos](#flujo-de-pagos)
7. [Webhooks y Notificaciones](#webhooks-y-notificaciones)
8. [Modelos y Base de Datos](#modelos-y-base-de-datos)
9. [Pruebas y Testing](#pruebas-y-testing)
10. [Solución de Problemas](#solución-de-problemas)

## Descripción General

Este documento describe la implementación de la pasarela de pagos de Mercado Pago en el proyecto "Quiero Recordarte". Esta integración permite a los usuarios realizar el pago de membresías a través de Mercado Pago, procesando transacciones y actualizando el estado de las órdenes automáticamente.

## Requisitos Previos

- Ruby y Rails instalados
- Docker y Docker Compose configurados
- Cuenta de desarrollador en Mercado Pago
- Credenciales de API de Mercado Pago (Access Token y Public Key)

## Estructura de la Implementación

La implementación consta de los siguientes componentes principales:

1. **Modelos**:
   - `Order`: Almacena información sobre los pedidos y su estado
   - `Customer`: Datos del cliente que realiza la compra
   - `Membership`: Detalles de la membresía activada después del pago

2. **Controlador de Pagos**: 
   - `PaymentsController`: Maneja la creación de preferencias de pago, webhooks y consultas de estado

3. **Configuración**:
   - Inicializador de Mercado Pago
   - Variables de entorno para credenciales

4. **Rutas API**:
   - Endpoints para la creación de preferencias y gestión de webhooks

## Instalación

El script de instalación realiza los siguientes pasos automáticamente:

1. Verifica los prerrequisitos (Ruby, Bundle, Rails)
2. Agrega la gema de Mercado Pago al Gemfile
3. Instala las dependencias
4. Crea el inicializador de Mercado Pago
5. Genera los modelos necesarios
6. Crea el controlador de pagos
7. Actualiza las rutas de la aplicación
8. Ejecuta las migraciones de la base de datos

Para ejecutar el script de instalación:

```bash
chmod +x install_mercadopago.sh
./install_mercadopago.sh
```

## Configuración

### Configuración de Variables de Entorno

Después de la instalación, es necesario configurar las credenciales de Mercado Pago:

```bash
# En desarrollo
docker compose exec app /bin/bash -c 'echo "ENV['"'"'MP_ACCESS_TOKEN'"'"']='"'"'TEST-XXXX'"'"'" >> .env'
docker compose exec app /bin/bash -c 'echo "ENV['"'"'MP_PUBLIC_KEY'"'"']='"'"'TEST-XXXX'"'"'" >> .env'

# URLs de retorno
docker compose exec app /bin/bash -c 'echo "ENV['"'"'FRONTEND_URL'"'"']='"'"'http://localhost:5000'"'"'" >> .env'
docker compose exec app /bin/bash -c 'echo "ENV['"'"'BACKEND_URL'"'"']='"'"'http://localhost:3000'"'"'" >> .env'
```




prueba1 ---> este tiene las keys de la app de prueba
user: TESTUSER164815429
pass: ebaf3282#0c77#4f29#

Comprador 1
user: TESTUSER552111881
pass: 5055a234#8eea#4c61#

APP mercado pago qr test user test

public key
APP_USR-b00061fc-8859-48a1-959c-b64bf7973071

access token
APP_USR-3664805261955273-032621-c0316d60db47a0fdf814212f8d4c825b-1461279103


client id
3664805261955273

client secret
uxSz8mIJTJ1vf5BFiPWDuXQftcwcSHTw

### Configuración del Inicializador

El archivo `config/initializers/mercado_pago.rb` contiene la configuración para diferentes entornos. Asegúrate de revisar y ajustar este archivo según sea necesario:

```ruby
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
```

## Flujo de Pagos

El flujo de pagos implementado sigue estos pasos:

1. **Creación de Preferencia**:
   - El usuario completa el formulario de compra
   - El backend crea una preferencia de pago en Mercado Pago
   - Se retorna el ID de preferencia y la URL de pago

2. **Proceso de Pago**:
   - El usuario es redirigido a la página de pago de Mercado Pago
   - Completa el pago con su método preferido

3. **Notificación y Redirección**:
   - Mercado Pago notifica al backend a través del webhook
   - El usuario es redirigido a la página de éxito/fallo/pendiente

4. **Actualización de Estado**:
   - El backend actualiza el estado de la orden según la notificación
   - Se activa la membresía si el pago es exitoso

## Webhooks y Notificaciones

El sistema implementa un endpoint de webhook para recibir notificaciones de Mercado Pago:

```
POST /api/v1/webhook
```

El webhook procesa los siguientes estados de pago:
- `approved`: Pago aprobado, se activa la membresía
- `rejected`: Pago rechazado
- `pending`: Pago pendiente
- `in_process`: Pago en proceso
- `refunded`: Pago reembolsado

Es importante asegurarse de que la URL del webhook sea accesible desde Internet en producción.

## Modelos y Base de Datos

### Order

```ruby
# == Schema Information
#
# Table name: orders
#
#  id              :bigint           not null, primary key
#  uuid            :string           indexed, unique
#  customer_id     :integer
#  membership_type :string
#  amount          :decimal
#  status          :string
#  payment_id      :string
#  created_at      :datetime         not null
#  updated_at      :datetime         not null
#
```

### Customer

```ruby
# == Schema Information
#
# Table name: customers
#
#  id          :bigint           not null, primary key
#  first_name  :string
#  last_name   :string
#  email       :string
#  phone       :string
#  address     :string
#  city        :string
#  province    :string
#  postal_code :string
#  created_at  :datetime         not null
#  updated_at  :datetime         not null
#
```

### Membership

```ruby
# == Schema Information
#
# Table name: memberships
#
#  id              :bigint           not null, primary key
#  order_id_id     :bigint           indexed
#  customer_id_id  :bigint           indexed
#  membership_type :string
#  status          :string
#  start_date      :datetime
#  end_date        :datetime
#  created_at      :datetime         not null
#  updated_at      :datetime         not null
#
```

## Pruebas y Testing

### Tarjetas de Prueba

Para probar la integración en ambiente de desarrollo, utiliza estas tarjetas de prueba:

| Tipo | Número | CVV | Fecha de Vencimiento |
|------|--------|-----|----------------------|
| VISA | 4509 9535 6623 3704 | 123 | 11/25 |
| MASTERCARD | 5031 7557 3453 0604 | 123 | 11/25 |

Para simular diferentes resultados:
- **Aprobación**: Usa cualquier documento válido
- **Rechazo**: Usa el documento 12345678

### Flujo de Prueba

1. Iniciar el servidor en desarrollo:
```bash
docker compose up
```

2. Acceder a la página de checkout

3. Completar el formulario y enviar

4. Confirmar que la redirección a Mercado Pago funciona correctamente

5. Realizar un pago de prueba con las tarjetas de test

6. Verificar que el webhook recibe la notificación (revisar logs)

7. Confirmar que la orden se actualiza en la base de datos

### Logs y Depuración

Para ver los logs durante las pruebas:

```bash
docker compose logs -f app
```

Verifica especialmente los logs cuando ocurren notificaciones de webhook.

## Solución de Problemas

### Problemas Comunes

1. **Webhook no recibe notificaciones**:
   - Verifica que la URL sea accesible públicamente
   - Usa ngrok para exponer temporalmente tu localhost
   - Revisa los logs de Mercado Pago en su panel de desarrollador

2. **Error en la creación de preferencia**:
   - Verifica las credenciales de API
   - Asegúrate de usar el token correcto para el entorno (test/prod)

3. **Migraciones fallidas**:
   - Ejecuta manualmente:
   ```bash
   docker compose exec app bundle exec bin/rails db:migrate:status
   docker compose exec app bundle exec bin/rails db:migrate
   ```

4. **Error en la activación de membresía**:
   - Verifica la lógica en el método `activate_membership`
   - Revisa los logs para errores específicos

### Depuración del Webhook

Para depurar problemas con el webhook, agrega logs temporales:

```ruby
# En el método webhook del PaymentsController
Rails.logger.info "Webhook recibido: #{params.inspect}"
```

Puedes utilizar herramientas como RequestBin o ngrok para inspeccionar las notificaciones recibidas.

## Referencias

- [Documentación oficial de Mercado Pago](https://www.mercadopago.com.ar/developers/es/docs/checkout-api/landing)
- [Referencia de la API de Preferencias](https://www.mercadopago.com.ar/developers/es/reference/preferences/_checkout_preferences/post)
- [Webhooks y notificaciones](https://www.mercadopago.com.ar/developers/es/docs/notifications/webhooks)