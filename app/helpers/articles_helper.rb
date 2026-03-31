module ArticlesHelper
  STATUS_STYLES = {
    "draft"          => { dot: "bg-gray-400", text: "text-gray-700", bg: "bg-gray-50 border-gray-200" },
    "pending_review"  => { dot: "bg-amber-400", text: "text-amber-700", bg: "bg-amber-50 border-amber-200" },
    "approved"       => { dot: "bg-blue-400", text: "text-blue-700", bg: "bg-blue-50 border-blue-200" },
    "published"      => { dot: "bg-emerald-400", text: "text-emerald-700", bg: "bg-emerald-50 border-emerald-200" },
    "rejected"       => { dot: "bg-red-400", text: "text-red-700", bg: "bg-red-50 border-red-200" }
  }.freeze

  def article_status_badge(status)
    s = STATUS_STYLES.fetch(status, STATUS_STYLES["draft"])
    content_tag(:span, class: "inline-flex items-center gap-1.5 px-2.5 py-1 rounded-full text-xs font-semibold border #{s[:bg]} #{s[:text]}") do
      content_tag(:span, "", class: "w-1.5 h-1.5 rounded-full #{s[:dot]}") + status.humanize
    end
  end
end
