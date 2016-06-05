module Test.JsonApi exposing (suite)

import ElmTest as Test
import Dict
import Debug
import List.Extra
import Json.Encode
import Json.Decode exposing (decodeString)
import JsonApi
import JsonApi.Decode
import JsonApi.Data exposing (Document, Resource(..), emptyLinks)
import JsonApi.OneOrMany exposing (OneOrMany(..))
import Test.Examples exposing (validPayload)


exampleDocument : Document
exampleDocument =
  case decodeString JsonApi.Decode.document validPayload of
    Ok doc ->
      doc

    Err string ->
      Debug.crash string


suite : Test.Test
suite =
  Test.suite
    "JsonApi core functions"
    [ primaryResource
    , primaryResourceCollection
    ]


primaryResource : Test.Test
primaryResource =
  Test.test
    "it returns an error when used incorrectly"
    (Test.assertEqual
      (Err "Expected a singleton resource, got a collection") 
      (JsonApi.primaryResource exampleDocument)
    )


primaryResourceCollection : Test.Test
primaryResourceCollection =
  let
    decodedPrimaryResource =
      case JsonApi.primaryResourceCollection exampleDocument of
        Err string ->
          Debug.crash string

        Ok resourceList ->
          case List.head resourceList of
            Nothing ->
              Debug.crash "Expected non-empty collection"

            Just (resource) ->
              resource

    decodedPrimaryResourceAttrs =
      JsonApi.attributes decodedPrimaryResource

    relatedCommentResource =
      case JsonApi.relatedResourceCollection "comments" decodedPrimaryResource of
        Err string ->
          Debug.crash string

        Ok commentResources ->
          case (List.Extra.find (\(Resource ident _) -> ident.id == "12") commentResources) of
            Nothing ->
              Debug.crash "Expected to find related comment with id 12"

            Just resource ->
              resource

    relatedCommentResourceAttrs =
      JsonApi.attributes relatedCommentResource

    relatedCommentAuthorResource =
      case JsonApi.relatedResource "author" relatedCommentResource of
        Err string ->
          Debug.crash string

        Ok resource ->
          resource

    relatedCommentAuthorResourceAttrs =
      JsonApi.attributes relatedCommentAuthorResource

    primaryAttributesAreDecoded =
      Test.assertEqual
        (Dict.get "title" decodedPrimaryResourceAttrs)
        (Just (Json.Encode.string "JSON API paints my bikeshed!"))

    relationshipAttributesAreDecoded =
      Test.assertEqual
        (Dict.get "body" relatedCommentResourceAttrs)
        (Just (Json.Encode.string "I like XML better"))

    relationshipsAreHydratedRecursively =
      Test.assertEqual
        (Dict.get "twitter" relatedCommentAuthorResourceAttrs)
        (Just (Json.Encode.string "dgeb"))

  in
    Test.suite
      "decoding and relationships"
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
