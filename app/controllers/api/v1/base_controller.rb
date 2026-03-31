module Api
  module V1
    class BaseController < ActionController::API
      include Authorization

      rescue_from ActiveRecord::RecordNotFound, with: :not_found
      rescue_from ActiveRecord::RecordInvalid, with: :unprocessable

      private

      def not_found
        render json: { error: "Not found" }, status: :not_found
      end

      def unprocessable(exception)
        render json: { error: exception.record.errors.full_messages }, status: :unprocessable_entity
      end

      def paginate(scope)
        per_page = [ (params[:per_page] || 20).to_i, 100 ].min
        page = [ params[:page].to_i, 1 ].max
        total = scope.count

        records = scope.offset((page - 1) * per_page).limit(per_page)

        {
          records: records,
          meta: { page: page, per_page: per_page, total: total, total_pages: (total.to_f / per_page).ceil }
        }
      end

      # API auth via session (same as web) — token auth can be added later
      def current_user
        @current_user ||= User.find_by(id: session[:user_id]) if session[:user_id]
      end

      def require_api_auth
        render json: { error: "Unauthorized" }, status: :unauthorized unless current_user
      end
    end
  end
end
