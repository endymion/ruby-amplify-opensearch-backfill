# Ruby Amplify OpenSearch Backfill

There's a Python script called [ddb_to_es.py](https://github.com/aws-amplify/amplify-category-api/blob/main/packages/graphql-elasticsearch-transformer/scripts/ddb_to_es.py) that AWS provides for anyone who needs to "backfill" an OpenSearch index for any given Amplify model, for when the index drifts out of sync when an app is operated over long time scales.

But, we use Ruby.  Yes, even for Amplify projects.  We wanted code we could incorporate into our Ruby CLI for our own Amplify project.

If you need to reindex an Amplify model from Ruby code then here you go, reusable code with a CLI wrapped around it.  You can either manually dig up the ARN for the table and the stream and the streaming function and call it like the AWS `ddb_to_es.py` script, or you can just tell it what model you want to reindex and it will do enough introspection into your Amplify app and stacks to find those things for you.

## Backfilling a table manually

Use `backfill.rb raw`, like this:

```bash

```