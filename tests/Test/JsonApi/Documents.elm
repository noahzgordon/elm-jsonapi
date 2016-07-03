module Test.JsonApi.Documents exposing (suite)

import ElmTest as Test
import Dict
import Debug
import List.Extra
import Json.Encode
import Json.Decode exposing (decodeString)
import JsonApi.Decode
import JsonApi.Data exposing (emptyLinks)
import JsonApi exposing (Document, Resource)
import JsonApi.Documents
import JsonApi.Resources
import Test.Examples exposing (validPayload, recursivePayload)


suite : Test.Test
suite =
    Test.suite "JsonApi core functions"
        [ primaryResourceErrors
        , resourceChaining
        , resourceCircularReferences
        , jsonapiObject
        ]


primaryResourceErrors : Test.Test
primaryResourceErrors =
    Test.test "it returns an error when used incorrectly"
        (Test.assertEqual (Err "Expected a singleton resource, got a collection")
            (JsonApi.Documents.primaryResource exampleDocument)
        )


resourceChaining : Test.Test
resourceChaining =
    let
        decodedPrimaryResource =
            case JsonApi.Documents.primaryResourceCollection exampleDocument of
                Err string ->
                    Debug.crash string

                Ok resourceList ->
                    case List.head resourceList of
                        Nothing ->
                            Debug.crash "Expected non-empty collection"

                        Just resource ->
                            resource

        decodedPrimaryResourceAttrs =
            JsonApi.Resources.attributes decodedPrimaryResource

        relatedCommentResource =
            case JsonApi.Resources.relatedResourceCollection "comments" decodedPrimaryResource of
                Err string ->
                    Debug.crash string

                Ok commentResources ->
                    case (List.Extra.find (\resource -> (JsonApi.Resources.id resource) == "12") commentResources) of
                        Nothing ->
                            Debug.crash "Expected to find related comment with id 12"

                        Just resource ->
                            resource

        relatedCommentResourceAttrs =
            JsonApi.Resources.attributes relatedCommentResource

        relatedCommentAuthorResource =
            case JsonApi.Resources.relatedResource "author" relatedCommentResource of
                Err string ->
                    Debug.crash string

                Ok resource ->
                    resource

        relatedCommentAuthorResourceAttrs =
            JsonApi.Resources.attributes relatedCommentAuthorResource

        primaryAttributesAreDecoded =
            Test.assertEqual (Dict.get "title" decodedPrimaryResourceAttrs)
                (Just (Json.Encode.string "JSON API paints my bikeshed!"))

        relationshipAttributesAreDecoded =
            Test.assertEqual (Dict.get "body" relatedCommentResourceAttrs)
                (Just (Json.Encode.string "I like XML better"))

        relationshipsAreHydratedRecursively =
            Test.assertEqual (Dict.get "twitter" relatedCommentAuthorResourceAttrs)
                (Just (Json.Encode.string "dgeb"))
    in
        Test.suite "decoding and relationships"
            [ Test.test "it extracts the primary data attributes from the document" primaryAttributesAreDecoded
            , Test.test "it extracts the relationship attributes" relationshipAttributesAreDecoded
            , Test.test "recursively hydrates relationships" relationshipsAreHydratedRecursively
            ]


resourceCircularReferences : Test.Test
resourceCircularReferences =
    let
        primaryResourceResult =
            decodeString JsonApi.Decode.document recursivePayload
                `Result.andThen` JsonApi.Documents.primaryResource
                `Result.andThen` (JsonApi.Resources.relatedResource "author")
                `Result.andThen` (JsonApi.Resources.relatedResource "article")

        primaryResourceTitle =
            case primaryResourceResult of
                Ok resource ->
                    Dict.get "title" (JsonApi.Resources.attributes resource)

                Err string ->
                    Debug.crash string
    in
        Test.test "it can handle circular references in the payload"
            (Test.assertEqual (Just (Json.Encode.string "JSON API paints my bikeshed!"))
                primaryResourceTitle
            )


jsonapiObject : Test.Test
jsonapiObject =
    let
        expectedResult =
            Just
                { version = Just "1.0"
                , meta = Just (Json.Encode.object [ ( "foo", Json.Encode.string "bar" ) ])
                }
    in
        Test.test "it can extract jsonapi object information"
            (Test.assertEqual expectedResult (JsonApi.Documents.jsonapi exampleDocument))


exampleDocument : Document
exampleDocument =
    case decodeString JsonApi.Decode.document validPayload of
        Ok doc ->
            doc

        Err string ->
            Debug.crash string
