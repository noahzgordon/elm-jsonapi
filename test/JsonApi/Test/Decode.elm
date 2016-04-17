module JsonApi.Test.Decode (suite) where

import ElmTest
import Dict
import Debug
import Json.Encode
import Json.Decode exposing (decodeString)
import JsonApi.Decode exposing (emptyLinks, Document, SingletonOrCollection(..))
import Graphics.Element exposing (Element)


suite : ElmTest.Test
suite =
  ElmTest.suite "JsonApi Decoders" [ document ]


document : ElmTest.Test
document =
  let
    decodedPayload =
      case decodeString JsonApi.Decode.document examplePayload of
        Ok payload ->
          payload

        Err string ->
          Debug.crash string
  in
    ElmTest.test
      "it decodes an entire JsonApi document"
      {- we must test the equality of the inspected data structures
      because Dictionary equality is unreliable
      -}
      (ElmTest.assertEqual (toString expectedDocument) (toString decodedPayload))


expectedDocument : Document
expectedDocument =
  { data =
      Collection
        [ { id = "1"
          , resourceType = "articles"
          , attributes = Dict.singleton "title" (Json.Encode.string "JSON API paints my bikeshed!")
          , relationships =
              Dict.fromList
                [ ( "author"
                  , { data =
                        Singleton { id = "9", resourceType = "people" }
                    , links =
                        { self = Just "http://example.com/articles/1/relationships/author"
                        , related = Just "http://example.com/articles/1/author"
                        , first = Nothing
                        , last = Nothing
                        , prev = Nothing
                        , next = Nothing
                        }
                    , meta = Nothing
                    }
                  )
                , ( "comments"
                  , { data =
                        Collection
                          [ { id = "5", resourceType = "comments" }
                          , { id = "12", resourceType = "comments" }
                          ]
                    , links =
                        { self = Just "http://example.com/articles/1/relationships/comments"
                        , related = Just "http://example.com/articles/1/comments"
                        , first = Nothing
                        , last = Nothing
                        , prev = Nothing
                        , next = Nothing
                        }
                    , meta = Nothing
                    }
                  )
                ]
          , links = { emptyLinks | self = Just "http://example.com/articles/1" }
          }
        ]
  , included =
      [ { id = "9"
        , resourceType = "people"
        , attributes =
            Dict.fromList
              [ ( "first-name", (Json.Encode.string "Dan") )
              , ( "last-name", (Json.Encode.string "Gebhardt") )
              , ( "twitter", (Json.Encode.string "dgeb") )
              ]
        , relationships = Dict.empty
        , links = { emptyLinks | self = Just "http://example.com/people/9" }
        }
      , { id = "5"
        , resourceType = "comments"
        , attributes = Dict.singleton "body" (Json.Encode.string "First!")
        , relationships =
            Dict.singleton
              "author"
              { data = Singleton { id = "2", resourceType = "people" }
              , links = emptyLinks
              , meta = Nothing
              }
        , links = { emptyLinks | self = Just "http://example.com/comments/5" }
        }
      , { id = "12"
        , resourceType = "comments"
        , attributes = Dict.singleton "body" (Json.Encode.string "I like XML better")
        , relationships =
            Dict.singleton
              "author"
              { data = Singleton { id = "9", resourceType = "people" }
              , links = emptyLinks
              , meta = Nothing
              }
        , links =
            { emptyLinks | self = Just "http://example.com/comments/12" }
        }
      ]
  , links =
      { self = Just "http://example.com/articles"
      , related = Nothing
      , first = Nothing
      , last = Just "http://example.com/articles?page[offset]=10"
      , prev = Nothing
      , next = Just "http://example.com/articles?page[offset]=2"
      }
  , meta = Nothing
  }



{- example payload copied from JsonApi official website: http://jsonapi.org/ -}


examplePayload : String
examplePayload =
  """
  {
    "links": {
      "self": "http://example.com/articles",
      "next": "http://example.com/articles?page[offset]=2",
      "last": "http://example.com/articles?page[offset]=10"
    },
    "data": [{
      "type": "articles",
      "id": "1",
      "attributes": {
        "title": "JSON API paints my bikeshed!"
      },
      "relationships": {
        "author": {
          "links": {
            "self": "http://example.com/articles/1/relationships/author",
            "related": "http://example.com/articles/1/author"
          },
          "data": { "type": "people", "id": "9" }
        },
        "comments": {
          "links": {
            "self": "http://example.com/articles/1/relationships/comments",
            "related": "http://example.com/articles/1/comments"
          },
          "data": [
            { "type": "comments", "id": "5" },
            { "type": "comments", "id": "12" }
          ]
        }
      },
      "links": {
        "self": "http://example.com/articles/1"
      }
    }],
    "included": [{
      "type": "people",
      "id": "9",
      "attributes": {
        "first-name": "Dan",
        "last-name": "Gebhardt",
        "twitter": "dgeb"
      },
      "links": {
        "self": "http://example.com/people/9"
      }
    }, {
      "type": "comments",
      "id": "5",
      "attributes": {
        "body": "First!"
      },
      "relationships": {
        "author": {
          "data": { "type": "people", "id": "2" }
        }
      },
      "links": {
        "self": "http://example.com/comments/5"
      }
    }, {
      "type": "comments",
      "id": "12",
      "attributes": {
        "body": "I like XML better"
      },
      "relationships": {
        "author": {
          "data": { "type": "people", "id": "9" }
        }
      },
      "links": {
        "self": "http://example.com/comments/12"
      }
    }]
  }
  """
