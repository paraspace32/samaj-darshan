module AdminHelper
  ROLE_COLORS = {
    "super_admin" => "bg-purple-100 text-purple-800",
    "editor"      => "bg-blue-100 text-blue-800",
    "co_editor"   => "bg-cyan-100 text-cyan-800",
    "moderator"   => "bg-amber-100 text-amber-800",
    "user"        => "bg-gray-100 text-gray-700"
  }.freeze

  def user_role_badge(role)
    classes = ROLE_COLORS.fetch(role, "bg-gray-100 text-gray-700")
    content_tag(:span, role.humanize, class: "inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-semibold #{classes}")
  end

  def admin_nav_link(label, path, icon_name)
    active = current_page?(path) || request.path.start_with?(URI.parse(path).path)

    base = "flex items-center gap-3 px-3 py-2.5 rounded-xl text-sm font-medium transition-all"
    classes = active ? "#{base} bg-white/10 text-white shadow-sm" : "#{base} text-gray-400 hover:bg-white/5 hover:text-gray-200"

    link_to path, class: classes do
      admin_icon(icon_name) + content_tag(:span, label)
    end
  end

  def admin_icon(name)
    icons = {
      "home" => '<path d="M3 12l2-2m0 0l7-7 7 7M5 10v10a1 1 0 001 1h3m10-11l2 2m-2-2v10a1 1 0 01-1 1h-3m-4 0h4"/>',
      "newspaper" => '<path d="M19 20H5a2 2 0 01-2-2V6a2 2 0 012-2h10a2 2 0 012 2v1m2 13a2 2 0 01-2-2V7m2 13a2 2 0 002-2V9a2 2 0 00-2-2h-2m-4-3H9M7 16h6M7 8h6v4H7V8z"/>',
      "map-pin" => '<path d="M17.657 16.657L13.414 20.9a1.998 1.998 0 01-2.827 0l-4.244-4.243a8 8 0 1111.314 0z"/><path d="M15 11a3 3 0 11-6 0 3 3 0 016 0z"/>',
      "tag" => '<path d="M7 7h.01M7 3h5c.512 0 1.024.195 1.414.586l7 7a2 2 0 010 2.828l-7 7a2 2 0 01-2.828 0l-7-7A1.994 1.994 0 013 12V7a4 4 0 014-4z"/>',
      "users" => '<path d="M12 4.354a4 4 0 110 5.292M15 21H3v-1a6 6 0 0112 0v1zm0 0h6v-1a6 6 0 00-9-5.197m13.5-9a2.5 2.5 0 11-5 0 2.5 2.5 0 015 0z"/>',
      "billboard" => '<path d="M4 16l4.586-4.586a2 2 0 012.828 0L16 16m-2-2l1.586-1.586a2 2 0 012.828 0L20 14m-6-6h.01M6 20h12a2 2 0 002-2V6a2 2 0 00-2-2H6a2 2 0 00-2 2v12a2 2 0 002 2z"/>',
      "book-open" => '<path d="M12 6.253v13m0-13C10.832 5.477 9.246 5 7.5 5S4.168 5.477 3 6.253v13C4.168 18.477 5.754 18 7.5 18s3.332.477 4.5 1.253m0-13C13.168 5.477 14.754 5 16.5 5c1.747 0 3.332.477 4.5 1.253v13C19.832 18.477 18.247 18 16.5 18c-1.746 0-3.332.477-4.5 1.253"/>',
      "video" => '<path d="M15 10l4.553-2.276A1 1 0 0121 8.618v6.764a1 1 0 01-1.447.894L15 14M5 18h8a2 2 0 002-2V8a2 2 0 00-2-2H5a2 2 0 00-2 2v8a2 2 0 002 2z"/>'
    }

    content_tag(:svg, icons.fetch(name, "").html_safe,
      xmlns: "http://www.w3.org/2000/svg",
      class: "w-5 h-5 shrink-0",
      fill: "none",
      viewBox: "0 0 24 24",
      stroke: "currentColor",
      "stroke-width": "1.5",
      "stroke-linecap": "round",
      "stroke-linejoin": "round"
    )
  end
end
