module TypeBalancer
  module Rails
    class Container
      class << self
        def register(key, value = nil, &block)
          if block_given?
            services[key] = block
          else
            services[key] = -> { value }
          end
        end

        def resolve(key)
          service = services[key]
          raise KeyError, "Service not registered: #{key}" unless service
          
          service.call
        end

        def services
          @services ||= {}
        end

        def reset!
          @services = {}
        end
      end
    end
  end
end 