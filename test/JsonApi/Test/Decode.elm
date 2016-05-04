module JsonApi.Test.Decode (suite) where

import ElmTest as Test
import Dict
import Debug
import List.Extra
import Json.Encode
import Json.Decode exposing (decodeString)
import JsonApi.Decode
import JsonApi.Data exposing (Document, HydratedResource(..), emptyLinks)
import JsonApi.OneOrMany exposing (OneOrMany(..))
import Graphics.Element exposing (Element)


suite : Test.Test
suite =
  Test.suite
    "JsonApi Decoders"
    [ primary ]


primary : Test.Test
primary =
  let
    decodedPrimaryResource =
      case decodeString JsonApi.Decode.primary examplePayload of
        Err string ->
          Debug.crash string

        Ok data ->
          case data of
            One resource ->
              Debug.crash "Expected collection of resources"

            Many resourceList ->
              case List.head resourceList of
                Nothing ->
                  Debug.crash "Expected non-empty collection"

                Just (HydratedResource primaryResource) ->
                  primaryResource

    relatedCommentResource =
      case Dict.get "comments" (decodedPrimaryResource.relationships) of
        Nothing ->
          Debug.crash "Expected comments relationship to be decoded"

        Just commentsRelationship ->
          case commentsRelationship.data of
            Nothing ->
              Debug.crash "Expected comment relationship data to be present"

            Just (One _) ->
              Debug.crash "Expected comment relationship to be a collection"

            Just (Many commentResources) ->
              case (List.Extra.find (\(HydratedResource resource) -> resource.id == "12") commentResources) of
                Nothing ->
                  Debug.crash "Expected to find related comment with id 12"

                Just (HydratedResource commentResource) ->
                  commentResource

    relatedCommentAuthorResource =
      case Dict.get "author" (relatedCommentResource.relationships) of
        Nothing ->
          Debug.crash "Expected 'author' relationship to be present on included comment resources"

        Just authorRelationship ->
          case authorRelationship.data of
            Nothing ->
              Debug.crash "Expected author relationship data to be present"

            Just (Many _) ->
              Debug.crash "Expected author relationship to be a singleton"

            Just (One (HydratedResource authorResource)) ->
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
