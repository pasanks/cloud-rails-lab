# Echoes pings from the /cable-test page. The reply goes through the pub/sub
# adapter in config/cable.yml (Redis/Valkey via REDIS_URL in production), so a
# reply proves both the WebSocket and the adapter work.
class PingChannel < ApplicationCable::Channel
  def subscribed
    stream_from "ping:#{params[:client_id]}"
  end

  def ping(data)
    ActionCable.server.broadcast("ping:#{params[:client_id]}",
      { message: data["message"], hostname: ProcessInfo.hostname, at: Time.current.utc.iso8601 })
  end
end
