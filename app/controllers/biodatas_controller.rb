class BiodatasController < ApplicationController
  def index
    @biodatas = Biodata.visible
                       .with_attached_photo
                       .for_gender(params[:gender])
                       .for_age_range(params[:age_min], params[:age_max])
                       .for_city(params[:city])
                       .for_education(params[:education])
    @per_page = 24
    @page = [ params[:page].to_i, 1 ].max
    @total_count = @biodatas.count
    @biodatas = @biodatas.offset((@page - 1) * @per_page).limit(@per_page)
  end

  def show
    @biodata = Biodata.published.find(params[:id])
  end
end
