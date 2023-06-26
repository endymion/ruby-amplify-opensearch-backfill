# Ruby Amplify OpenSearch Backfill

There's a Python script called [ddb_to_es.py](https://github.com/aws-amplify/amplify-category-api/blob/main/packages/graphql-elasticsearch-transformer/scripts/ddb_to_es.py) that AWS provides for anyone who needs to "backfill" an OpenSearch index for any given Amplify model, for when the index drifts out of sync when an app is operated over long time scales.

But, we use Ruby.  Yes, even for Amplify projects.  We wanted code we could incorporate into our Ruby CLI for our own Amplify project.

If you need to reindex an Amplify model from Ruby code then here you go, reusable code with a CLI wrapped around it.  You can either manually dig up the ARN for the table and the stream and the streaming function and call it like the AWS `ddb_to_es.py` script, or you can just tell it what model you want to reindex and it will do enough introspection into your Amplify app and stacks to find those things for you.

It does the introspection by looking at your `amplify-meta.json` file to find out the details about your "current" Amplify environment.  If you want to reindex tables in some other Amplify environment, maybe in some other account, then manually specify the root CloudFormation stack name with the `--stack-name` option.

## Installation

So far, this is only on GitHub and not in RubyGems.  So, put this in your Gemfile:

```ruby
gem 'ruby-amplify-opensearch-backfill', git: 'https://github.com/VenueDriver/ruby-amplify-opensearch-backfill', branch: 'production'
```

If you want to do local development then:

```bash
bundle config local.ruby-amplify-opensearch-backfill /path/to/ruby-amplify-opensearch-backfill
```

## Usage

### CLI

One of the ways to use this code is the packaged CLI tool.

```bash
$ osbackfill
Commands:
  osbackfill help [COMMAND]                   # Describe available commands or one specific command
  osbackfill raw --esarn --lfarn --rn --tn    # Reindex but with raw parameters.
  osbackfill reindex --api-name --model-name  # Reindex DynamoDB items for one model to OpenSearch.
  osbackfill status                           # Check current OpenSearch configuration for this Amplify app.
```

#### API credentials

To use the CLI, you'll need valid AWS credentials.  The simplest way is to use the standard [environment variables](https://docs.aws.amazon.com/cli/latest/userguide/cli-configure-envvars.html).

### Programmatically

Or, you can require the class in your Ruby code and do things with it:

```ruby
require 'awesome_print'
require 'ruby-amplify-opensearch-backfill'

ap AmplifyOpenSearchBackfill::Processor.status
```

### Reindex an Amplify model

#### CLI

Use the CLI command `osbackfill reindex`, like this:

```bash
$ osbackfill help reindex
Usage:
  osbackfill reindex --api-name=API_NAME --model-name=MODEL_NAME [--stack-name=STACK_NAME]

Options:
  --api-name    # Amplify API name
  --model-name  # Amplify model name
  --stack-name  # Specify explicitly instead of using stack from amplify-meta.json

Reindex DynamoDB items for one model to OpenSearch.
```

#### Programmatically

```ruby
require 'ruby-amplify-opensearch-backfill'

AmplifyOpenSearchBackfill::Processor.reindex(model_name:'Widget')
```

### Backfilling a table manually

#### CLI

```bash
$ exe/osbackfill help 
raw
Usage:
  osbackfill raw --esarn --lfarn --rn --tn

Options:
  --rn     # AWS region
  --tn     # DynamoDB table name (not the model name)
  --lfarn  # Lambda function ARN that posts data to OpenSearch
  --esarn  # Event source ARN

Reindex but with raw parameters.
```
