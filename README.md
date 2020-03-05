# LODQA Bot Server

It works as the engine of the LODQA system.
LODQA BS provides an API for several bot agent services to register queries for [LODQA](http://lodqa.org/) and to subscribe progress of the query.

LODQA (Linked Open Data Question-Answering) is a system to search SPARQL endpoints, using natural langauge queries, from which it generates SPARQL queries, submits them to SPARQL endpoints, collects answers, and present them to the users.

## Dependency

LODQA system is dependent on this external service for parsing the query:

- [Enju](http://kmcs.nii.ac.jp/enju/) CGI server at [http://enju-gtrec.dbcls.jp](http://enju-gtrec.dbcls.jp).

## Responsibility

LODQA deals queries that spend long time to perform.
This server enqueues queries and perform queries asynchronously.
Then after performing queries, callback API to send answer of queries.

## APIs

### Register query

POST /searches with below parameters:

-   query
-   callback_url

#### Curl exapmle:

    curl http://localhost/searches -d query='Which genes are associated with Endothelin receptor type B?' -d callback_url='https://webhook.site/310d4eab-d454-4087-954e-a4b1638c5af2'

#### Return value example:

```json
{
  "search_id": "f47bb3d7-f1c9-4720-a824-2baf4a78c757",
  "resouce_url": "http://localhost/searches/f47bb3d7-f1c9-4720-a824-2baf4a78c757",
  "subscribe_url": "http://localhost/searches/f47bb3d7-f1c9-4720-a824-2baf4a78c757/subscriptions"
}
```

#### Option parameters:

| name           | default value | description                                              |
| :------------- | :------------ | :------------------------------------------------------- |
| sparql_timeout | 5             | Duration in seconds to expire SPARQL                     |
| sparql_limit   | 100           | Limit on the number of SPARQL generated per anchored pgp |
| answer_limit   | 10            | Limit of number of results of SPARQL                     |
| cache          | yes           | Disable cache of answers of query if this value is 'no'  |

##### Curl exapmle:

    curl http://localhost/searches -d query='Which genes are associated with Endothelin receptor type B?' -d callback_url='https://webhook.site/310d4eab-d454-4087-954e-a4b1638c5af2' -d -sparql_timeout=1 -d sparql_limit=10 -d answer_limit=5 -d cache=no

#### callback

Post to `callback_url` when starting search and finishing search.

at start:

```json
{
  "event": "start",
  "query": "Which genes are associated with Endothelin receptor type F?",
  "search_id": "f47bb3d7-f1c9-4720-a824-2baf4a78c757",
  "start_at": "2018-09-06T16:50:21.937+09:00"
}
```

at finish:

```json
{
  "event": "finish",
  "query": "Which genes are associated with Endothelin receptor type F?",
  "search_id": "f47bb3d7-f1c9-4720-a824-2baf4a78c757",
  "start_at": "2018-09-06T16:50:21.937+09:00",
  "finish_at": "2018-09-06T16:52:21.584+09:00",
  "elapsed_time": 119.6461645,
  "answers": [
    {
      "uri": "http://www4.wiwiss.fu-berlin.de/diseasome/resource/genes/EDNRA",
      "label": "EDNRA"
    },
    {
      "uri": "http://www4.wiwiss.fu-berlin.de/diseasome/resource/genes/SOX10",
      "label": "SOX10"
    },
    {
      "uri": "http://www4.wiwiss.fu-berlin.de/diseasome/resource/genes/ESR1",
      "label": "ESR1"
    },
    {
      "uri": "http://www4.wiwiss.fu-berlin.de/diseasome/resource/genes/EDNRB",
      "label": "EDNRB"
    },
    {
      "uri": "http://www4.wiwiss.fu-berlin.de/diseasome/resource/genes/ATP1A2",
      "label": "ATP1A2"
    },
    {
      "uri": "http://bio2rdf.org/omim:131244",
      "label": "ENDOTHELIN RECEPTOR, TYPE B; EDNRB [omim:131244]"
    },
    {
      "uri": "http://bio2rdf.org/omim:131243",
      "label": "ENDOTHELIN RECEPTOR, TYPE A; EDNRA [omim:131243]"
    },
    {
      "uri": "http://www4.wiwiss.fu-berlin.de/diseasome/resource/genes/TNF",
      "label": "TNF"
    },
    {
      "uri": "http://www4.wiwiss.fu-berlin.de/diseasome/resource/genes/ATP8B1",
      "label": "ATP8B1"
    },
    {
      "uri": "http://www4.wiwiss.fu-berlin.de/diseasome/resource/genes/ECE1",
      "label": "ECE1"
    },
    {
      "uri": "http://www4.wiwiss.fu-berlin.de/diseasome/resource/genes/ABCB11",
      "label": "ABCB11"
    },
    {
      "uri": "http://www4.wiwiss.fu-berlin.de/diseasome/resource/genes/ABCB4",
      "label": "ABCB4"
    },
    {
      "uri": "http://www4.wiwiss.fu-berlin.de/diseasome/resource/genes/HSD3B7",
      "label": "HSD3B7"
    }
  ]
}
```

### Get query

GET /searches/:search_id

    curl http://localhost/searches/f47bb3d7-f1c9-4720-a824-2baf4a78c757

#### Return value example:

```json
{
  "search_id": "f47bb3d7-f1c9-4720-a824-2baf4a78c757",
  "query": "Which genes are associated with Endothelin receptor type G?",
  "created_at": "2018-09-06 16:55:05 +0900",
  "started_at": "2018-09-06 16:55:05 +0900",
  "finished_at": null,
  "aborted_at": "2018-09-06 17:06:53 +0900",
  "read_timeout": 5,
  "sparql_limit": 100,
  "answer_limit": 10,
  "start_search_callback_url": "https://webhook.site/460584f3-e880-4647-913d-d5abf89821b8",
  "finish_search_callback_url": "https://webhook.site/460584f3-e880-4647-913d-d5abf89821b8",
  "answers": [

  ]
}
```

### Subscribe the query

POST /searches/:search_id/subscriptions withe blow parameters:

-   callback_url

#### Curl example:

    curl http://localhost/searches/f47bb3d7-f1c9-4720-a824-2baf4a78c757/subscriptions -d callback_url='https://webhook.site/310d4eab-d454-4087-954e-a4b1638c5af2'

Returns no value.

#### callback

Post to `callback_url` when any event of searching occurs.

Example event:

```json
{
  "events": [
    {
      "event": "datasets",
      "dataset": {
        "name": "QALD-BioMed",
        "number": 1
      }
    },
    {
      "event": "datasets",
      "dataset": {
        "name": "DisGeNET",
        "number": 3
      }
    }
  ]
}
```

## Page to maintenance

Open /searches.
List enqueued queries and their state.

## To Develop

### Start the server

    docker-compose build
    docker-compose up
