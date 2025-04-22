module ApplicationCable
  class Channel < ActionCable::Channel::Base
    def tagged_logger
      Rails.logger
    end
  end
end
