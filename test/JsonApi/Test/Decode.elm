module JsonApi.Test.Decode (suite) where

import ElmTest as Test
import Dict
import Debug
import Json.Encode
import Json.Decode exposing (decodeString)
import JsonApi.Decode exposing (emptyLinks, Document)
import JsonApi.OneOrMany exposing (OneOrMany(..))
import Graphics.Element exposing (Element)


suite : Test.Test
suite =
  Test.suite
    "JsonApi Decoders"
    [ document
    , primary
    ]


primary : Test.Test
primary =
  let
    decodedPrimaryResource =
      case decodeString JsonApi.Decode.primary examplePayload of
        Err string ->
          Debug.crash string

        Ok data ->
          case data of
            Singleton resource ->
              Debug.crash "Expected collection of resources"

            Collection resourceList ->
              case List.head resourceList of
                Nothing ->
                  Debug.crash "Expected non-empty collection"

                Just primaryResource ->
                  primaryResource

    relatedCommentResource =
      case Dict.get "comments" (decodedPrimaryResource.relationships) of
        Nothing ->
          Debug.crash "Expected comments relationship to be decoded"

        Just commentsRelationship ->
          case commentsRelationship.data of
            Nothing ->
              Debug.crash "Expected comment relationship data to be present"

            Just (Singleton _) ->
              Debug.crash "Expected comment relationship to be a collection"

            Just (Collection commentResources) ->
              case (List.head <| List.filter (\resource -> resource.id == "12") commentResources) of
                Nothing ->
                  Debug.crash "Expected to find related comment with id 12"

                Just commentResource ->
                  commentResource

    relatedCommentAuthorResource =
      case Dict.get "author" (relatedCommentResource.relationships) of
        Nothing ->
          Debug.crash "Expected 'author' relationship to be present on included comment resources"

        Just authorRelationship ->
          case authorRelationship.data of
            Nothing ->
              Debug.crash "Expected author relationship data to be present"

            Just (Collection _) ->
              Debug.crash "Expected author relationship to be a singleton"

            Just (Singleton authorResource) ->
              authorResource

    primaryAttributesAreDecoded =
      Test.assertEqual
        (Dict.get "title" decodedPrimaryResource.attributes)
        (Just (Json.Encode.string "JSON API paints my bikeshed!"))

    relationshipAttributesAreDecoded =
      Test.assertEqual
        (Dict.get "body" relatedCommentResource.attributes)
        (Just (Json.Encode.string "I like XML better"))

    relationshipsAreHydratedRecursively =
      Test.assertEqual
        (Dict.get "twitter" relatedCommentAuthorResource.attributes)
        (Just (Json.Encode.string "dgeb"))

  in
    Test.suite
      "primary function"
      [ Test.test "it extracts the primary data attributes from the document" primaryAttributesAreDecoded
      , Test.test "it extracts the relationship attributes" relationshipAttributesAreDecoded
      , Test.test "recursively hydrates relationships" relationshipsAreHydratedRecursively
      ]


document : Test.Test
document =
  let
    decodedPayload =
      case decodeString JsonApi.Decode.document examplePayload of
        Ok payload ->
          payload

        Err string ->
          Debug.crash string
  in
    Test.test
      "it decodes an entire JsonApi document"
      {- we must test the equality of the inspected data structures
      because Dictionary equality is unreliable
      -}
      (Test.assertEqual (toString expectedDocument) (toString decodedPayload))


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
