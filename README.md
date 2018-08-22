# What's this ?

This is the LODQA Bot Server.

This provide APIs for several bot agent servers to register queries for [LODQA](http://lodqa.org/) and to subscribe progress of the query.


## Architecture

LODQA deals quereis that spend long time to perform. This server enqueues queries and perform queries asynchronously. Then after performing queris, callback API to send answer of queries.


## APIs

### Register query

POST /queries with below parameters:

- query
- start_search_callback_url
- finish_search_callback_url

Curl exapmle:

```
curl http://localhost:81/queries -d query='Which genes are associated with Endothelin receptor type B?' -d start_search_callback_url='https://webhook.site/310d4eab-d454-4087-954e-a4b1638c5af2' -d finish_search_callback_url='https://webhook.site/310d4eab-d454-4087-954e-a4b1638c5af2'
```

### Subscribe the query

POST /queries/:query_id/subscriptions withe blow parameters:

- callback_url

Curl example:

```
curl http://localhost:81/queries/c1bac9f9-a44d-4461-94bb-c87d86c406fd/subscriptions -d callback_url='https://webhook.site/310d4eab-d454-4087-954e-a4b1638c5af2'
```

## To Develop

### Start the server

```
docker-compose build
docker-compose up
```
