module ApplicationHelper
  STATUS_STYLES = {
    ok: "bg-green-100 text-green-800",
    missing: "bg-gray-200 text-gray-700",
    error: "bg-red-100 text-red-800"
  }.freeze

  # A coloured OK / MISSING / ERROR pill.
  def status_badge(status, label = status.to_s.upcase)
    tag.span(label, class: "rounded px-2 py-0.5 text-xs font-semibold #{STATUS_STYLES.fetch(status)}")
  end

  def utc_time(time)
    time.utc.strftime("%Y-%m-%d %H:%M:%S UTC")
  end
end
