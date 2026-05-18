namespace :visits do
  desc "Re-flag bot visits using the latest BOT_PATTERNS regex"
  task reflag_bots: :environment do
    updated = 0
    Visit.where(bot: false).find_each(batch_size: 500) do |visit|
      if Visit.bot_user_agent?(visit.user_agent)
        visit.update_column(:bot, true)
        updated += 1
      end
    end
    puts "Marked #{updated} visits as bots."
  end
end
