class MemorialsController < ApplicationController
  before_action :set_memorial, only: %i[ show edit update destroy ]

  # GET /memorials/1
  def show
    @memorial = set_memorial
    
    if @memorial.is_private? && !session["memorial_#{@memorial.id}_authorized"]
      redirect_to verify_pin_memorial_path(@memorial)
    end
  end

  # GET /memorials/new
  def new
    @memorial = Memorial.new(user: current_user)
  end

  # GET /memorials/1/edit
  def edit
  end

  # POST /memorials
  def create
    @memorial = current_user.memorials.new(memorial_params)

    if @memorial.save
      redirect_to root_path, notice: "Memorial was successfully created."
    else
      render :new, status: :unprocessable_entity
    end
  end

  # PATCH/PUT /memorials/1
  def update
    if @memorial.update(memorial_params)
      redirect_to @memorial, notice: "Memorial was successfully updated.", status: :see_other
    else
      render :edit, status: :unprocessable_entity
    end
  end

  # DELETE /memorials/1
  def destroy
    @memorial.destroy!
    redirect_to memorials_url, notice: "Memorial was successfully destroyed.", status: :see_other
  end
  
  # Display PIN verification form
  def verify_pin
    @memorial = Memorial.find(params[:id])
  end
  
  # Verify the entered PIN
  def check_pin
    @memorial = Memorial.find(params[:id])
    
    if @memorial.pin_code == params[:pin_code]
      session["memorial_#{@memorial.id}_authorized"] = true
      redirect_to session[:return_to] || @memorial
      session.delete(:return_to)
    else
      flash.now[:alert] = 'Código PIN incorrecto'
      render :verify_pin
    end
  end
  
  # Mostrar formulario para asociar QR
  def attach_qr_form
    @memorial = current_user.memorials.find(params[:id])
    @available_qr_codes = QrCode.available
  end

  # Procesar la asociación de QR
  def attach_qr
    @memorial = current_user.memorials.find(params[:id])
    @qr_code = QrCode.find(params[:qr_code_id])
    
    if @qr_code.available?
      @qr_code.update(memorial_id: @memorial.id)
      redirect_to @memorial, notice: 'Memorial asociado exitosamente con el código QR.'
    else
      redirect_to attach_qr_form_memorial_path(@memorial), 
        alert: 'El código QR seleccionado ya no está disponible.'
    end
  end

  # Mostrar memorial usando código QR
  def show_by_qr
    @qr_code = QrCode.find_by!(code: params[:code])
    
    if @qr_code.memorial.nil?
      redirect_to root_path, alert: 'Este QR no está asociado a ningún memorial.'
      return
    end
    
    @memorial = @qr_code.memorial
    
    # Verificar privacidad
    if @memorial.is_private? && !session["memorial_#{@memorial.id}_authorized"]
      session[:return_to] = memorial_by_qr_path(@qr_code.code)
      redirect_to verify_pin_memorial_path(@memorial)
      return
    end
    
    # registrar la visita
    MemorialVisit.create(memorial: @memorial, ip: request.remote_ip)
    
    render :show
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_memorial
      @memorial = current_user.memorials.find(params[:id])
    end

    # Only allow a list of trusted parameters through.
    def memorial_params
      params.require(:memorial).permit(:is_private, :pin_code, 
        :dob,
        :bio,
        :caption,
        :dod,
        :first_name,
        :hero_image,
        :last_name,
        :profile_image,
        :religion,
        :user_id,
        photos: []
      )
    end
end