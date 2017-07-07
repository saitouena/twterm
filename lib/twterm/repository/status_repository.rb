require 'twterm/repository/abstract_expirable_entity_repository'
require 'twterm/status'

module Twterm
  module Repository
    class StatusRepository < AbstractExpirableEntityRepository
      def all
        repository.values
      end

      def delete(id)
        @touched_at.delete(id)
        repository.delete(id)
      end

      def find_replies_for(id)
        repository.values.select { |s| s.in_reply_to_status_id == id }
      end

      def ids
        repository.keys
      end

      private

      def type
        Status
      end
    end
  end
end
