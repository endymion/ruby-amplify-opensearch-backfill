module AmplifyOpenSearchBackfill

  class CLI < Thor
    default_task :help

    desc 'status', 'Check current OpenSearch configuration for this Amplify app.'
    option :api_name, required: true, desc: 'Amplify API name', banner: ''
    option :stack_name, required: true, desc: 'CloudFormation stack name', banner: ''
    option :model_name, required: true, desc: 'Amplify model name', banner: ''
    def status
      AmplifyOpenSearchBackfill::Introspector.new(
        api_name:   options['api_name'],
        model_name: options['model_name'],
        stack_name: options['stack_name']
      ).status
    end

    desc 'unindexed', 'Find DynamoDB items that are not in OpenSearch.'
    def unindexed
      AmplifyOpenSearchBackfill::Processor.new.unindexed
    end

    desc 'reindex', 'Reindex DynamoDB items for one model to OpenSearch.'
    option :api_name, required: true, desc: 'Amplify API name', banner: ''
    option :stack_name, required: true, desc: 'CloudFormation stack name', banner: ''
    option :model_name, required: true, desc: 'Amplify model name', banner: ''
    def reindex
      AmplifyOpenSearchBackfill::Processor.new.reindex(
        api_name: options['api_name'],
        model_name: options['model_name'],
        stack_name: options['stack_name']
      )
    end

    desc 'raw', 'Same as reindex, but uses raw parameters.'
    option :rn, required: true, desc: 'AWS region', banner: ''
    option :tn, required: true, desc: 'DynamoDB table name (not the model name)', banner: ''
    option :lfarn, required: true, desc: 'Lambda function ARN that posts data to OpenSearch', banner: ''
    option :esarn, required: true, desc: 'Event source ARN', banner: ''
    def raw
      domain = AmplifyOpenSearchBackfill::Processor.new

      domain.import_dynamodb_items_to_es(
        region: options[:rn],
        table_name: options[:tn],
        event_source_arn: options[:esarn],
        lambda_function_arn: options[:lfarn]
      )
    end

    def self.exit_on_failure?
      true
    end

  end

end