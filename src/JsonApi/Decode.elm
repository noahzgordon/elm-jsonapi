module JsonApi.Decode exposing (document, errors)

{-| Library for decoding JSONAPI-compliant payloads

@docs document, errors
-}

import Json.Decode exposing (..)
import Json.Decode.Pipeline exposing (decode, required, optional, hardcoded)
import Result exposing (Result)
import Dict
import JsonApi exposing (ErrorObject)
import JsonApi.OneOrMany as OneOrMany exposing (OneOrMany(..), extractOne, extractMany)
import JsonApi.Data exposing (..)


{-| Decode a JSONAPI-compliant payload.
-}
document : Decoder Document
document =
    map Document documentObject


documentObject : Decoder DocumentObject
documentObject =
    decode DocumentObject
        |> required "data" data
        |> optional "included" (list resource) []
        |> optional "links" links emptyLinks
        |> optional "jsonapi" jsonApiObject Nothing
        |> optional "meta" meta Nothing


{-| Decode the errors returned from a JSON API-compliant server.
-}
errors : Decoder (List ErrorObject)
errors =
    field "errors" (list errorObject)


errorObject : Decoder ErrorObject
errorObject =
    decode ErrorObject
        |> optional "id" (maybe string) Nothing
        |> optional "links" (maybe errorLinks) Nothing
        |> optional "status" (maybe string) Nothing
        |> optional "code" (maybe string) Nothing
        |> optional "title" (maybe string) Nothing
        |> optional "detail" (maybe string) Nothing
        |> optional "source" (maybe source) Nothing
        |> optional "meta" meta Nothing


source : Decoder Source
source =
    decode Source
        |> optional "pointer" (maybe string) Nothing
        |> optional "parameter" (maybe string) Nothing


errorLinks : Decoder ErrorLinks
errorLinks =
    decode ErrorLinks
        |> optional "about" (maybe string) Nothing


meta : Decoder Meta
meta =
    maybe value


jsonApiObject : Decoder (Maybe JsonApiObject)
jsonApiObject =
    decode JsonApiObject
        |> optional "version" (maybe string) Nothing
        |> optional "meta" meta Nothing
        |> maybe


data : Decoder (OneOrMany RawResource)
data =
    oneOf
        [ Json.Decode.map Many (list resource)
        , Json.Decode.map One resource
        ]


resource : Decoder RawResource
resource =
    map2 RawResource resourceIdentifier resourceObject


resourceObject : Decoder ResourceObject
resourceObject =
    decode ResourceObject
        |> optional "attributes" attributes Nothing
        |> optional "relationships" relationships Dict.empty
        |> optional "links" links emptyLinks
        |> optional "meta" meta Nothing


links : Decoder Links
links =
    decode Links
        |> optional "self" link Nothing
        |> optional "related" link Nothing
        |> optional "first" link Nothing
        |> optional "last" link Nothing
        |> optional "prev" link Nothing
        |> optional "next" link Nothing


link : Decoder Link
link =
    maybe string


attributes : Decoder Attributes
attributes =
    maybe value


relationships : Decoder Relationships
relationships =
    dict relationship


relationship : Decoder Relationship
relationship =
    decode Relationship
        |> required "data" relationshipData
        |> optional "links" links emptyLinks
        |> optional "meta" meta Nothing


relationshipData : Decoder (OneOrMany ResourceIdentifier)
relationshipData =
    oneOf
        [ Json.Decode.map Many (list resourceIdentifier)
        , Json.Decode.map One resourceIdentifier
        ]


resourceIdentifier : Decoder ResourceIdentifier
resourceIdentifier =
    decode ResourceIdentifier
        |> required "id" string
        |> required "type" string
