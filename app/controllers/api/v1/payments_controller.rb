# frozen_string_literal: true

module Api
  module V1
    class PaymentsController < ApplicationController
      require 'mercadopago'
      require 'securerandom'
      
      # En tu PaymentsController
      skip_before_action :verify_authenticity_token, only: [:webhook, :create_preference]
      after_action :set_cors_headers
      # # Manejo de solicitudes OPTIONS
      # def options
      #   head :ok
      # end
      
      def create_preference
        # Al inicio del método, agrega esto:
        Rails.logger.info "FRONTEND_URL: #{ENV['FRONTEND_URL']}"
        Rails.logger.info "BACKEND_URL: #{ENV['BACKEND_URL']}"
        # Manejar las solicitudes OPTIONS preflight
        if request.method == "OPTIONS"
          return head :ok
        end

        # Obtiene los datos del formulario
        membership_type = params[:membershipType].downcase
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
          back_url: {
            success: "#{ENV['FRONTEND_URL']}/success?order_id=#{order_id}",
            failure: "#{ENV['FRONTEND_URL']}/failure?order_id=#{order_id}",
            pending: "#{ENV['FRONTEND_URL']}/pending?order_id=#{order_id}"
          },
          # URL de retorno para el pago tiene que activarse no se puede a localhost
          auto_return: "approved",
          # Referencia externa para asociar esta preferencia con tu orden
          external_reference: order_id,
          # Notificación de webhook
          notification_url: "#{ENV['BACKEND_URL']}/api/v1/webhook"
        }
        
        Rails.logger.info "Success URL: #{preference_data[:back_urls][:success]}"
        Rails.logger.info "Failure URL: #{preference_data[:back_urls][:failure]}"
        Rails.logger.info "Pending URL: #{preference_data[:back_urls][:pending]}"

        # Crea la preferencia en Mercado Pago
        preference_response = sdk.preference.create(preference_data)
        Rails.logger.info "MercadoPago response status: #{preference_response[:status]}"
        Rails.logger.info "MercadoPago response body: #{preference_response[:response].inspect}"
        # Verifica la respuesta
        if preference_response[:status] >= 200 and preference_response[:status] < 300
          # Devuelve los datos necesarios al frontend
          render json: {
            id: preference_response[:response]['id'],
            init_point: preference_response[:response]['init_point'],
            orderId: order_id
          }
        else
          # Maneja el error
          render json: { error: 'Error al crear la preferencia de pago', 
                          message: preference_response[:response]
          }, status: :unprocessable_entity
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
          
          if payment_response[:status] >= 200 and payment_response[:status] < 300
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
      
      def set_cors_headers
        headers['Access-Control-Allow-Origin'] = '*'
        headers['Access-Control-Allow-Methods'] = 'POST, GET, OPTIONS'
        headers['Access-Control-Allow-Headers'] = '*'
        headers['Access-Control-Max-Age'] = '86400'
      end

      # Método para obtener detalles de la membresía
      def get_membership_details(membership_type)
        memberships = {
          'acompanandote' => {
            name: 'Acompañandote',
            price: 12,
          },
          'recordandote' => {
            name: 'Recordandote',
            price: 15,
          },
          'siempre' => {
            name: 'Siempre Juntos',
            price: 18,
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
