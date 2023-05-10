require 'json'
require 'logger'
require 'thor'
require 'aws-sdk-dynamodb'
require 'aws-sdk-lambda'

module AmplifyOpenSearchBackfill
  class Domain
    attr_accessor :client, :reports, :object_amount, :part_size

    def initialize
      @logger = Logger.new(STDOUT)
      @logger.level = Logger::INFO
      @client = nil
      @reports = []
      @object_amount = 0
      @part_size = 0
    end

    def import_dynamodb_items_to_es(table_name, region, event_source_arn, lambda_function, scan_limit, credentials)
      @client = Aws::Lambda::Client.new(region: region, credentials: credentials)
      dynamodb = Aws::DynamoDB::Resource.new(region: region, credentials: credentials)
      table = dynamodb.table(table_name)
      ddb_keys_name = table.key_schema.map { |a| a.attribute_name }

      response = nil
      loop do
        response = if response.nil?
                     table.scan(limit: scan_limit)
                   else
                     table.scan(exclusive_start_key: response.last_evaluated_key, limit: scan_limit)
                   end

        response.items.each do |item|
          ddb_keys = item.select { |k, _| ddb_keys_name.include?(k) }
          record = {
            "dynamodb" => { "SequenceNumber" => "0000", "Keys" => ddb_keys, "NewImage" => item },
            "awsRegion" => region,
            "eventName" => "MODIFY",
            "eventSourceARN" => event_source_arn,
            "eventSource" => "aws:dynamodb"
          }
          @part_size += 1
          @object_amount += 1
          @logger.info(@object_amount)
          @reports << record

          if @part_size >= 100
            send_to_eslambda(lambda_function)
          end
        end

        break unless response.last_evaluated_key
      end

      send_to_eslambda(lambda_function) if @part_size.positive?
    end

    def send_to_eslambda(lambda_function)
      records_data = { "Records" => @reports }
      records = JSON.dump(records_data)
      lambda_response = @client.invoke(function_name: lambda_function, payload: records)

      @reports = []
      @part_size = 0

      puts lambda_response
    end
  end
end