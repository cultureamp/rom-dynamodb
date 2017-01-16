module ROM
  module Dynamo
    class Dataset
      attr_reader :name, :operation, :config

      attr_accessor :queries

      def initialize(name:, operation: :query, config: {}, queries: [])
        @name = name
        @operation = operation
        @config = config
        @queries = queries
      end

      def limit(num = nil)
        append { { limit: num } unless num.nil? }
      end

      def start(key)
        append { { exclusive_start_key: key } unless key.nil? }
      end

      def batch_get(query = nil)
        append(:batch_get) { query }
      end

      def restrict(query = nil)
        append(:query) { query }
      end

      def retrieve(query = nil)
        append(:get_item) { query }
      end

      def scan(query = nil)
        append(:scan) { query }
      end

      def build(parts = queries)
        parts.inject(:deep_merge).merge(table_name: name)
      end

      def update(key, hash, action = 'PUT')
        data = hash.delete_if { |k, _| key.keys.include?(k) }
        update = to_update_structure(data)
        payload = build([update, { key: key }])
        connection.update_item(payload).data
      end

      def create(hash)
        payload = build([{ item: hash }])
        connection.put_item(payload).attributes
      end

      def delete(hash)
        payload = build([{ key: hash }])
        connection.delete_item(payload).data
      end

      def information
        connection.describe_table build([{}]).table
      end

      def each(&block)
        each_item(build, &block)
      end

      def connection
        @connection ||= Aws::DynamoDB::Client.new(@config)
      end

      def execute(query)
        @response ||= case operation
        when :batch_get
          connection.send(operation, { request_items: { name => query } })
        else
          connection.send(operation, query).data
        end
      end

      private

      def each_item(body, &block)
        case operation
        when :get_item
          block.call execute(body).item
        when :batch_get
          execute(body).responses[name.to_s].each(&block)
        else
          execute(body).items.each(&block)
        end
      end

      def append(operation = :query, &block)
        result = block.call
        if result
          args = { name: name, config: config, operation: operation }
          self.class.new(args.merge(queries: queries + [result].flatten))
        else
          self
        end
      end

      def to_update_structure(hash)
        values = {}
        maps = {}
        expr = 'SET ' + hash.map do |key, val|
          values[":#{key}"] = val
          maps["##{key}"] = key
          "##{key}=:#{key}"
        end.join(', ')
        {
          expression_attribute_values: values,
          expression_attribute_names: maps,
          update_expression: expr
        }
      end
    end
  end
end