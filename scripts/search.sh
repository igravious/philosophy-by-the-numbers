curl -X GET 'http://localhost:9200/corpus/_search?pretty' -d '{
  "query": {
    "bool": {
      "must": {
        "nested": {
          "path": "snapshot.events.event.array.paper",
          "filter": {
            "bool": {
              "must": [{
                "match": {
                  "snapshot.events.event.array.paper.content": {
                    "query": "ultimately"
                  }
                }
              }]
            }
          }
        }
      }
    }
  }
}'
