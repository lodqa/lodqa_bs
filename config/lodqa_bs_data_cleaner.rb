# We persistently maintaine state of Search in the database and use the Active Job Async adapter as Active Job Adaptor.
# Searches that are enqueued or running will never change state from enqueued or running state once the Rails server stoped.
# We will manually abort them when starting the Rails server.
# Because it is easy to implement, We chose to do this at startup, not at server exit.
DbConnection.using { puts 'Abort unfinished searches' if PseudoGraphPattern.abort_unfinished_searches! }

# Delete old data periodically
Thread.new do
  loop do
    DbConnection.using { PseudoGraphPattern.prune }
    sleep 1.day
  end
end