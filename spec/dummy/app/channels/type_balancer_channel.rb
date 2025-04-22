# frozen_string_literal: true

class TypeBalancerChannel < ApplicationCable::Channel
  def subscribed
    return reject if params[:collection].blank?

    stream_from stream_name
  end

  def unsubscribed
    stop_all_streams
  end

  def update_cursor(data)
    cursor_position = data&.[]('cursor_position') || data&.[](:cursor_position)
    broadcast_message('update_cursor', cursor_position)
  end

  private

  # changed: allow unknown actions to be routed through method_missing
  def processable_action?(_action)
    true
  end

  # changed: always pass data to actions, bypassing arity check
  def dispatch_action(action, data)
    public_send(action, data)
  end

  def method_missing(method, data = {})
    # unchanged: extract both string and symbol keys for cursor_position
    cursor_position = data&.[]('cursor_position') || data&.[](:cursor_position)

    broadcast_message(method.to_s, cursor_position)
  end

  # changed: acknowledge dynamic actions
  def respond_to_missing?(_method_name, _include_private = false)
    true
  end

  def stream_name
    "type_balancer_#{params[:collection]}"
  end

  def broadcast_message(action, cursor_position)
    ActionCable.server.broadcast(
      stream_name,
      {
        action: action,
        cursor_position: cursor_position,
        collection: params[:collection]
      }
    )
  end
end
