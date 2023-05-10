class AmplifyOpenSearchBackfillCLI < Thor
  default_task :help

  desc 'status', 'Check current OpenSearch configuration for this Amplify app.'
  def status
  end

  # TODO: This idea from GitHub Copilot seems useful.
  # desc 'find', 'Find DynamoDB items that are not in OpenSearch.'
  # def find
  # end

  desc 'reindex', 'Reindex DynamoDB items for one model to OpenSearch.'
  option :model_name, required: true, aliases: '-m', desc: 'Amplify model name'
  def reindex
  end

  desc 'raw', 'Reindex but with raw parameters.'
  option :region, required: true, aliases: '-r', desc: 'AWS region'
  option :table_name, required: true, aliases: '-t', desc: 'DynamoDB table name'
  option :lambda_function, required: true, aliases: '-f', desc: 'Lambda function that posts data to OpenSearch'
  option :event_source_arn, required: true, aliases: '-e', desc: 'Event source ARN'
  def raw
    domain = OpenSearch::Domain.new
    credentials = Aws::SharedCredentials.new

    domain.import_dynamodb_items_to_es(
      options[:table_name],
      options[:region],
      options[:event_source_arn],
      options[:lambda_function],
      300,
      credentials
    )
  end

  def self.exit_on_failure?
    true
  end
end