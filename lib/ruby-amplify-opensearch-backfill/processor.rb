require 'json'
require 'logger'
require 'thor'
require 'aws-sdk-dynamodb'
require 'aws-sdk-lambda'

module AmplifyOpenSearchBackfill
  class Processor
    include Loggable

    def reindex(api_name:, model_name:)
      context = AmplifyOpenSearchBackfill::Introspector.new(
        api_name: api_name,
        model_name: model_name
      ).get_context

      raw_backfill(
        region: context[:region],
        table_name: context[:model_table_name],
        event_source_arn: context[:model_table_stream_arn],
        lambda_function_arn: context[:streaming_function_resource_arn]
      )
    end

    def raw_backfill(
      region:, table_name:,
      event_source_arn:, lambda_function_arn:,
      scan_limit: 1000)
      reports = []
      part_size = 0
      object_amount = 0

      dynamodb = Aws::DynamoDB::Resource.new(region: region)
      serializer = DynamoDBSerializer.new
      table = dynamodb.table(table_name)
      ddb_keys_name = table.key_schema.map { |key| key.attribute_name }
      last_evaluated_key = nil
    
      loop do
        response =
          if last_evaluated_key.nil?
            table.scan(limit: scan_limit)
          else
            table.scan(
              exclusive_start_key: last_evaluated_key,
              limit: scan_limit
            )
          end

        response.items.each do |item|
          ddb_keys = item.select { |k, _| ddb_keys_name.include?(k) }
          record = {
            "dynamodb" => {
              "SequenceNumber" => "0000",
              "Keys" => serializer.serialize(ddb_keys),
              "NewImage" => serializer.serialize(item)
            },
            "awsRegion" => region,
            "eventName" => "MODIFY",
            "eventSourceARN" => event_source_arn,
            "eventSource" => "aws:dynamodb"
          }
    
          part_size += 1
          object_amount += 1
          logger.debug(object_amount)
          reports << record
    
          if part_size >= 100
            send_to_eslambda(
              region: region,
              reports: reports,
              part_size: part_size,
            lambda_function_arn: lambda_function_arn
            )
            reports.clear
            part_size = 0
          end
        end
    
        last_evaluated_key = response.last_evaluated_key
        break if last_evaluated_key.nil?
      end
    
      send_to_eslambda(
        region: region,
        reports: reports,
        part_size: part_size,
        lambda_function_arn: lambda_function_arn
      ) if part_size.positive?
    end
    
    private
    
    def send_to_eslambda(region:, reports:, part_size:, lambda_function_arn:)
      lambda_client = Aws::Lambda::Client.new(region: region)
      records_data = { "Records" => reports }
      records = records_data.to_json

      logger.debug 'Records: ' + records

      lambda_response = lambda_client.invoke(
        function_name: lambda_function_arn,
        payload: records
      )

      logger.debug 'Lambda response: ' + lambda_response.ai
      logger.debug 'Lambda response headers: ' +
        lambda_response.context.http_response.headers.map{
          |k, v| "#{k}: #{v}"
        }.join(', ')
    end

  end


  class DynamoDBSerializer
    def serialize(data)
      case data
      when Hash
        data.map { |k, v| [k, serialize(v)] }.to_h
      when Array
        { 'L' => data.map { |v| serialize(v) } }
      when String
        { 'S' => data }
      when Integer
        { 'N' => data.to_s }
      when BigDecimal
        { 'N' => data.to_s('F').sub(/\.?0+$/, '') }
      when true, false
        { 'BOOL' => data }
      when nil
        { 'NULL' => true }
      else
        raise "Unsupported data type: #{data.class}"
      end
    end
  
    def deserialize(serialized_data)
      key, value = serialized_data.first
      case key
      when 'M'
        value.map { |k, v| [k, deserialize(v)] }.to_h
      when 'L'
        value.map { |v| deserialize(v) }
      when 'S'
        value
      when 'N'
        value.to_i
      when 'BOOL'
        value
      when 'NULL'
        nil
      else
        raise "Unsupported data type: #{key}"
      end
    end
  end

end
