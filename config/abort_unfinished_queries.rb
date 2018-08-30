# We persistently maintaine state of Query  in the database and use the Active Job Async adapter as Active Job Adaptor.
# Queries that are enqueued or running will never change state from enqueued or running state once the Rails server stoped.
# We will manually abort them when starting the Rails server.
# Because it is easy to implement, We chose to do this at startup, not at server exit.
DbConnection.using { Query.abort_unfinished_queries }