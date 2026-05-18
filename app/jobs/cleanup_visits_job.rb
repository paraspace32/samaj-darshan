class CleanupVisitsJob < ApplicationJob
  queue_as :default

  def perform
    # Hash IPs older than 30 days (privacy)
    Visit.where(visited_at: ...30.days.ago)
         .where.not(ip_address: [ nil, "hashed" ])
         .in_batches(of: 1000)
         .update_all(ip_address: "hashed")

    # Delete records older than 12 months
    Visit.where(visited_at: ...12.months.ago)
         .in_batches(of: 1000)
         .delete_all

    Rails.logger.info "[CleanupVisitsJob] Completed at #{Time.current}"
  end
end
