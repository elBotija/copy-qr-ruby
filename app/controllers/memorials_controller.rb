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
      redirect_to @memorial
    else
      flash.now[:alert] = 'Código PIN incorrecto'
      render :verify_pin
    end
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