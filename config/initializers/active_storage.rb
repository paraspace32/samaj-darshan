Rails.application.config.after_initialize do
  ActiveStorage::BaseController.after_action only: [ :show ] do
    response.set_header("Cache-Control", "public, max-age=#{1.year.to_i}, immutable") if response.status == 200
  end
end
