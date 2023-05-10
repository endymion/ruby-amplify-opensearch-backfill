Gem::Specification.new do |spec|
  spec.name        = 'ruby-amplify-opensearch-backfill'
  spec.version     = '0.1.0'
  spec.date        = '2023-05-09'
  spec.summary     = "Ruby Amplify OpenSearch Backfill magic."
  spec.description = "A gem with a CLI and a library to backfill OpenSearch from DynamoDB for Amplify apps."
  spec.authors     = ["Ryan Porter"]
  spec.email       = 'ryan.porter@taogroup.com'
  spec.files       = Dir["lib/**/*", "README.md", "LICENSE"]
  spec.require_paths = ["lib"]
  spec.homepage    = 'https://github.com/VenueDriver/ticketing-workload-monorepo'
  spec.add_runtime_dependency 'bundler', '~> 2.0'
  spec.add_development_dependency "guard"
  spec.add_development_dependency "guard-rake"
  spec.add_development_dependency "rb-fsevent"
  spec.add_development_dependency "byebug"
  spec.add_development_dependency "pry"
  spec.add_development_dependency "awesome_print"
  spec.add_development_dependency "rainbow"
  spec.add_development_dependency "dotenv"
  spec.add_development_dependency "rspec"
  spec.add_development_dependency "test-unit"
  spec.add_development_dependency "mocha"
  spec.add_development_dependency "simplecov"
  spec.add_runtime_dependency "aws-sdk-cloudformation"
  spec.add_runtime_dependency "aws-sdk-lambda"
  spec.add_runtime_dependency "aws-sdk-opensearchservice"
  spec.add_runtime_dependency "aws-sdk-dynamodb"
  spec.bindir        = 'exe'
  spec.executables   = ["osbackfill"]
end
