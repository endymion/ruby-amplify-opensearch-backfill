require 'pathname'
require 'aws-sdk-cloudformation'
require 'aws-sdk-lambda'
require 'aws-sdk-opensearchservice'

module AmplifyOpenSearchBackfill
  class Introspector
    include Loggable

    def initialize(api_name:, model_name:)
      @api_name = api_name
      @model_name = model_name
    end

    def status
      context = get_context

      logger.info "region: #{context[:region]}"
      logger.info "model table name: #{context[:model_table_name]}"
      logger.info "model table stream ARN: #{context[:model_table_stream_arn]}"
      logger.info "streaming function ARN: #{context[:streaming_function_resource_arn]}"
      logger.info "OpenSearch dashboard endpoint: #{context[:opensearch_kibana_endpoint]}"
      logger.info 'Documentation on how to access that endpoint URL: https://docs.aws.amazon.com/opensearch-service/latest/developerguide/obtain-domain-info.html'
    end

    def find_amplify_meta_json(starting_directory = Dir.pwd)
      @amplify_meta_json_path ||= begin
        current_directory = starting_directory
        file_path = nil
    
        loop do
          file_path = File.join(current_directory, 'amplify', 'backend', 'amplify-meta.json')
          if File.exist?(file_path)
            logger.debug "Found amplify-meta.json at #{file_path}"
            break
          end
    
          new_directory = File.dirname(current_directory)
          break if new_directory == current_directory
    
          current_directory = new_directory
        end
    
        raise 'amplify-meta.json not found in the current directory or any parent directories.' unless file_path && File.exist?(file_path)
        file_path
      end
    end

    def get_context
      # Get the resources for the top-level, root stack.
      resources = get_stack_resources(stack_name)

      # Get the resources for the nested, child stack for the API.
      api_stack_physical_id = resources.
        select{|resource|
          resource[:resource_type].eql? 'AWS::CloudFormation::Stack'
        }.select{|resource|
          resource[:logical_resource_id] =~ /#{Regexp.escape(@api_name)}/i
        }.first[:physical_resource_id]
      api_resources =
        get_stack_resources(api_stack_physical_id)

      model_stack_physical_id = api_resources.
        select{|resource|
          resource[:resource_type].eql? 'AWS::CloudFormation::Stack'
        }.select{|resource|
          resource[:logical_resource_id].downcase.eql? @model_name.downcase
        }.first[:physical_resource_id]
      model_stack_outputs =
        get_stack_outputs(model_stack_physical_id)

      model_table_name =
        model_stack_outputs.select{|output|
          output[:output_key] =~ /TableName/i
        }.first[:output_value]

      model_table_stream_arn =
        model_stack_outputs.select{|output|
          output[:output_key] =~ /TableStreamArn$/
        }.first[:output_value]

      # Get the @searchable stack.
      searchable_stack_physical_id = api_resources.
        select{|resource|
          resource[:resource_type].eql? 'AWS::CloudFormation::Stack'
        }.select{|resource|
          resource[:logical_resource_id].eql? 'SearchableStack'
        }.first[:physical_resource_id]
      searchable_stack_resources =
        get_stack_resources(searchable_stack_physical_id)

      opensearch_kibana_endpoint = searchable_stack_resources.
        select{|resource|
          resource[:resource_type].eql? 'AWS::Elasticsearch::Domain'
        }.select{|resource|
          resource[:logical_resource_id].eql? 'OpenSearchDomain'
        }.first[:kibana_url]

      streaming_function_resource_arn =
        searchable_stack_resources
        .select{|resource|
          resource[:resource_type].eql? 'AWS::Lambda::Function'
        }.select{|resource|
          resource[:logical_resource_id] =~
            /^OpenSearchStreamingLambdaFunction/i
        }.first[:resource_arn]

      {
        region: region,
        model_table_name: model_table_name,
        model_table_stream_arn: model_table_stream_arn,
        streaming_function_resource_arn: streaming_function_resource_arn,
        opensearch_kibana_endpoint: opensearch_kibana_endpoint
      }
    end

    private

    # Parse the amplify-meta.json file to get the current region.
    def region
      amplify_meta = File.read(
        self.find_amplify_meta_json
      )
      JSON.parse(amplify_meta)['providers']['awscloudformation']['Region']
    end

    # Parse the amplify-meta.json file to get the OpenSearch stack name.
    def stack_name
      amplify_meta = File.read(
        find_amplify_meta_json
      )
      JSON.parse(amplify_meta)['providers']['awscloudformation']['StackName']
    end

    def get_stack_resources(stack_name)
      cloudformation = Aws::CloudFormation::Client.new

      stack_resources = []

      begin
        response =
          cloudformation.describe_stack_resources({
            stack_name: stack_name
          })
        # logger.debug "resources: #{response.stack_resources.ai}}"

        response.stack_resources.each do |resource|
          stack_resources << {
            logical_resource_id: resource.logical_resource_id,
            physical_resource_id: resource.physical_resource_id,
            resource_type: resource.resource_type,
            resource_status: resource.resource_status
          }

          resource_arn =
            if resource.resource_type == 'AWS::Lambda::Function'
              get_lambda_function_arn(resource.physical_resource_id)
            end
          stack_resources.last[:resource_arn] = resource_arn unless resource_arn.nil?

          kibana_url =
            if [
              'AWS::OpenSearchService::Domain',
              'AWS::Elasticsearch::Domain'
            ].include? resource.resource_type
              get_opensearch_kibana_url(resource.physical_resource_id)
            end
          stack_resources.last[:kibana_url] = kibana_url unless kibana_url.nil?
        end
      rescue Aws::CloudFormation::Errors::ServiceError => e
        puts "Error: #{e}"
      end

      stack_resources
    end

    def get_stack_outputs(stack_name)
      cloudformation = Aws::CloudFormation::Client.new

      stack_outputs = []

      begin
        resp = cloudformation.describe_stacks({
          stack_name: stack_name
        })

        resp.stacks.each do |stack|
          stack.outputs.each do |output|
            stack_outputs << {
              output_key: output.output_key,
              output_value: output.output_value
            }
          end
        end
      rescue Aws::CloudFormation::Errors::ServiceError => e
        puts "Error: #{e}"
      end

      stack_outputs
    end

    def get_lambda_function_arn(function_name)
      lambda_client = Aws::Lambda::Client.new

      begin
        resp = lambda_client.get_function({ function_name: function_name })
        resp.configuration.function_arn
      rescue Aws::Lambda::Errors::ServiceError => e
        puts "Error: #{e}"
      end
    end

    def get_opensearch_kibana_url(domain_name)
      opensearch = Aws::OpenSearchService::Client.new

      begin
        resp = opensearch.describe_domain({ domain_name: domain_name })
        domain_endpoint = resp.domain_status.endpoint
        kibana_url = "https://#{domain_endpoint}/_plugin/kibana/"
      rescue Aws::OpenSearchService::Errors::ServiceError => e
        puts "Error: #{e}"
      end

      kibana_url
    end
  end
end
