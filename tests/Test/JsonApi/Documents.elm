module Test.JsonApi.Documents exposing (suite)

import Debug
import Dict
import Expect
import Json.Decode exposing (decodeString, decodeValue, field)
import Json.Encode
import JsonApi exposing (Document, Resource)
import JsonApi.Data exposing (emptyLinks)
import JsonApi.Decode
import JsonApi.Documents
import JsonApi.Resources
import List.Extra
import Test
import Test.Examples exposing (recursivePayload, validPayload)


suite : Test.Test
suite =
    Test.describe "JsonApi core functions"
        [ primaryResourceErrors
        , resourceChaining
        , resourceCircularReferences
        , jsonapiObject
        ]


primaryResourceErrors : Test.Test
primaryResourceErrors =
    Test.test "it returns an error when used incorrectly"
        (\_ ->
            Expect.equal (Err "Expected a singleton resource, got a collection")
                (JsonApi.Documents.primaryResource exampleDocument)
        )


resourceChaining : Test.Test
resourceChaining =
    let
        decodedPrimaryResource =
            case JsonApi.Documents.primaryResourceCollection exampleDocument of
                Err string ->
                    Debug.todo string

                Ok resourceList ->
                    case List.head resourceList of
                        Nothing ->
                            Debug.todo "Expected non-empty collection"

                        Just resource ->
                            resource

        decodedPrimaryResourceAttribute =
            JsonApi.Resources.attributes (field "title" Json.Decode.string) decodedPrimaryResource
                |> Result.toMaybe
                |> Maybe.withDefault ""

        relatedCommentResource =
            case JsonApi.Resources.relatedResourceCollection "comments" decodedPrimaryResource of
                Err string ->
                    Debug.todo string

                Ok commentResources ->
                    case List.Extra.find (\resource -> JsonApi.Resources.id resource == "12") commentResources of
                        Nothing ->
                            Debug.todo "Expected to find related comment with id 12"

                        Just resource ->
                            resource

        relatedCommentResourceAttribute =
            JsonApi.Resources.attributes (field "body" Json.Decode.string) relatedCommentResource
                |> Result.toMaybe
                |> Maybe.withDefault ""

        relatedCommentAuthorResource =
            case JsonApi.Resources.relatedResource "author" relatedCommentResource of
                Err string ->
                    Debug.todo string

                Ok maybeResource ->
                    case maybeResource of
                        Nothing ->
                            Debug.todo "Expected to find comment author, but was null"

                        Just resource ->
                            resource

        relatedCommentAuthorResourceAttribute =
            JsonApi.Resources.attributes (field "twitter" Json.Decode.string) relatedCommentAuthorResource
                |> Result.toMaybe
                |> Maybe.withDefault ""

        primaryAttributesAreDecoded =
            \_ -> Expect.equal decodedPrimaryResourceAttribute "JSON API paints my bikeshed!"

        relationshipAttributesAreDecoded =
            \_ -> Expect.equal relatedCommentResourceAttribute "I like XML better"

        relationshipsAreHydratedRecursively =
            \_ -> Expect.equal relatedCommentAuthorResourceAttribute "dgeb"
    in
    Test.describe "decoding and relationships"
        [ Test.test "it extracts the primary data attributes from the document" primaryAttributesAreDecoded
        , Test.test "it extracts the relationship attributes" relationshipAttributesAreDecoded
        , Test.test "recursively hydrates relationships" relationshipsAreHydratedRecursively
        ]


resourceCircularReferences : Test.Test
resourceCircularReferences =
    let
        primaryResourceResult =
            decodeString JsonApi.Decode.document recursivePayload
                |> Result.mapError Json.Decode.errorToString
                |> Result.andThen JsonApi.Documents.primaryResource
                |> Result.andThen (Result.fromMaybe "primary resource was null")
                |> Result.andThen (JsonApi.Resources.relatedResource "author")
                |> Result.andThen (Result.fromMaybe "author was null")
                |> Result.andThen (JsonApi.Resources.relatedResource "article")

        primaryResourceTitle =
            case primaryResourceResult of
                Ok maybeResource ->
                    case maybeResource of
                        Just resource ->
                            JsonApi.Resources.attributes (field "title" Json.Decode.string) resource
                                |> Result.toMaybe
                                |> Maybe.withDefault ""

                        Nothing ->
                            Debug.todo "Expected to find an article, but it was null"

                Err string ->
                    Debug.todo string
    in
    Test.test "it can handle circular references in the payload"
        (\_ -> Expect.equal "JSON API paints my bikeshed!" primaryResourceTitle)


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
        (\_ -> Expect.equal expectedResult (JsonApi.Documents.jsonapi exampleDocument))


exampleDocument : Document
exampleDocument =
    case
        decodeString JsonApi.Decode.document validPayload
            |> Result.mapError Json.Decode.errorToString
    of
        Ok doc ->
            doc

        Err string ->
            Debug.todo string
