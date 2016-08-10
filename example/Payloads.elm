module Payloads exposing (..)


user : String
user =
  """
  {
    "data": {
      "type": "people",
      "id": "1",
      "attributes": {
        "first_name": "Luke",
        "last_name": "Skywalker"
      },
      "relationships": {
        "sister": {
          "data": { "type": "people", "id": "2" }
        },
        "parents": {
          "data": [
            { "type": "people", "id": "3" },
            { "type": "people", "id": "4" }
          ]
        }
      }
    },
    "included": [{
      "type": "people",
      "id": "2",
      "attributes": {
        "first_name": "Leia",
        "last_name": "Organa"
      },
      "relationships": {
        "husband": {
          "data": { "type": "people", "id": "5" }
        }
      }
    }, {
      "type": "people",
      "id": "3",
      "attributes": {
        "first_name": "Anakin",
        "last_name": "Skywalker"
      }
    }, {
      "type": "people",
      "id": "4",
      "attributes": {
        "first_name": "Padme",
        "last_name": "Amidala"
      }
    }, {
      "type": "people",
      "id": "5",
      "attributes": {
        "first_name": "Han",
        "last_name": "Solo"
      }
    }]
  }
  """
