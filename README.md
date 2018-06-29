# What's this ?

This is the LODQA Bot Server. This provide APIs for several bot clients to register query jobs and query progress of jobs.

LODQA deals queris that spend long time to perform. This server enqueues queries and perform queries asynchronously. Then after performing queris, callback API to send answer of queries.

## Architecture

LODQA_BS is a API sever with the job queue.
We implements this server by [Ruby on rails](https://rubyonrails.org/) and [Sidekiq](https://sidekiq.org/).
