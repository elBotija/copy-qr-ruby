module OrdersHelper
  def order_status_color(status)
    case status
    when 'completed'
      'success'
    when 'pending'
      'warning'
    when 'rejected'
      'danger'
    when 'in_process'
      'info'
    when 'refunded'
      'secondary'
    else
      'light'
    end
  end
  
  def shipping_status_color(status)
    case status
    when 'pending'
      'secondary'
    when 'shipped'
      'primary'
    when 'in_transit'
      'info'
    when 'delivered'
      'success'
    when 'returned'
      'warning'
    when 'lost'
      'danger'
    else
      'light'
    end
  end
end
