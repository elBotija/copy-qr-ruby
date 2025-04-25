class HomeController < ApplicationController

  # GET /
  def index
    @memorials = current_user.memorials
  end
end
