class ShortlistsController < ApplicationController
  before_action :require_login

  def index
    @shortlists = current_user.shortlists.includes(:biodata).order(created_at: :desc)
    @biodatas = @shortlists.map(&:biodata)
  end
end
