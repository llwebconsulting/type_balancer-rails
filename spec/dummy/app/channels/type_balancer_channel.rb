class TypeBalancerChannel < ApplicationCable::Channel
  def subscribed
    stream_from "type_balancer_#{params[:collection]}"
  end

  def unsubscribed
    stop_all_streams
  end

  def receive(data)
    ActionCable.server.broadcast(
      "type_balancer_#{params[:collection]}",
      {
        action: data['action'],
        cursor_position: data['cursor_position'],
        collection: params[:collection]
      }
    )
  end
end
