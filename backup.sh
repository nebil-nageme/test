#!/bin/sh

#ES_HOST="localhost"
#ES_PORT="9200"
TMP="_v2"
echo "****  Script Execution Started ****"
echo " "
echo "**** Fetching List of Indices Elasticsearch Reindexing ****"
curl -s -X GET 'http://localhost:9200/_cat/indices/%2A?v=&s=index:desc'

echo " "
sleep 5

indices_list=$(curl -s -X GET 'http://localhost:9200/_cat/indices/%2A?v=&s=index:desc' | awk '{print $3}' | sed -n '1!p')
#indices=$(curl -s "http://${ES_HOST}:${ES_PORT}/_cat/indices/abc_*?h=index" | egrep 'abc_[0-9a-f]{8}-([0-9a-f]{4}-){3}[0-9a-f]{8}*')

# do for all abc elastic indices
count=0
echo "$indices_list"
for index in $indices_list
do
    echo " "
    echo "**** Index No: $count ****"
    echo "**** Present Index we are iterating:  ${index} ****"
    count=`expr $count + 1`
    echo " "
    echo " "
    echo "Reindex process starting for index: $index"
    tmp_index=$index${TMP}
    output=$(curl -s -X PUT "http://localhost:9200/$tmp_index" -H 'Content-Type: application/json' -d'
    {
        "settings" : {
            "index" : {
                "number_of_shards" : 5,
                "number_of_replicas" : 1
            }
        }
    }')
    echo " "
    echo "Temporary index: $tmp_index created with output: $output"
    echo "Starting reindexing elastic data from original index: $index to temporary index: $tmp_index"
    output=$(curl -s -X POST "http://localhost:9200/_reindex" -H 'Content-Type: application/json' -d'
    {
      "source": {
        "index": "'$index'"
      },
      "dest": {
        "index": "'$tmp_index'"
      }
    }
    ')
    echo " "
    echo "Reindexing completed from original index: $index to temporary index: $tmp_index with output: $output"
    echo " "
    echo "Deleting $index"
    output=$(curl -s -X DELETE "http://localhost:9200/$index")
    echo "$index deleted with status: $output"
    echo " "
done



