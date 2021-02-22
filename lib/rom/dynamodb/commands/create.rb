require "rom/commands/create"

module ROM
  module DynamoDB
    module Commands
      class Create < ROM::Commands::Create
        adapter :dynamodb

        def execute(tuples)
          tuples = tuples.is_a?(Array) ? tuples : [tuples]
          tuples.collect(&method(:with_tuple))
        end

        def with_tuple(tuple)
          data = tuple.is_a?(Hash) ? tuple : tuple.to_h
          source.create(data)
        end
      end
    end
  end
end
