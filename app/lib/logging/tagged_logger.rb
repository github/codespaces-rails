require 'logging'

module Logging
  class TaggedLogger
    LEVELS = [:debug, :info, :warn, :error, :fatal, :unknown].freeze

    def tag(tags)
      Logging.mdc[thread_id] = { tags: [] } if Logging.mdc[thread_id].nil?
      Logging.mdc[thread_id][:tags].push(tags)

      self
    end

    ::Logger.instance_methods(false).select { |method| LEVELS.include?(method) }.each do |level|
      define_method(level) do |*args, &block|
        Rails.logger.tagged(current_tags).send(level, *args, &block)
      end
    end

    def current_tags
      return [] if Logging.mdc[thread_id].nil?

      Logging.mdc[thread_id][:tags] || []
    end

    def cleanup
      Logging.mdc.delete(thread_id)
    end

    private

    def thread_id
      Thread.current.object_id
    end
  end
end
