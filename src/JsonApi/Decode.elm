module JsonApi.Decode exposing (document)

{-| Library for decoding JSONAPI-compliant payloads

@docs document
-}

import Json.Decode exposing (..)
import Json.Decode.Pipeline exposing (decode, required, optional, hardcoded)
import Result exposing (Result)
import Dict

import JsonApi.OneOrMany as OneOrMany exposing (OneOrMany(..), extractOne, extractMany)
import JsonApi.Data exposing (..)



{-| Decode a JSONAPI-compliant payload.
-}
document : Decoder Document
document =
  decode Document
    |> required "data" rawData
    |> optional "included" (list rawResource) []
    |> optional "links" links emptyLinks
    |> optional "meta" meta Nothing


meta : Decoder Meta
meta =
  maybe value


rawData : Decoder RawData
rawData =
  oneOf
    [ Json.Decode.map Many (list rawResource)
    , Json.Decode.map One rawResource
    ]


rawResource : Decoder RawResource
rawResource =
  object2 RawResource resourceIdentifier rawResourceObject


rawResourceObject : Decoder RawResourceObject
rawResourceObject =
  decode RawResourceObject
    |> optional "attributes" attributes Dict.empty
    |> optional "relationships" rawRelationships Dict.empty
    |> optional "links" links emptyLinks


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
  dict value


rawRelationships : Decoder RawRelationships
rawRelationships =
  dict rawRelationship


rawRelationship : Decoder RawRelationship
rawRelationship =
  decode RawRelationship
    |> required "data" rawRelationshipData
    |> optional "links" links emptyLinks
    |> optional "meta" meta Nothing


rawRelationshipData : Decoder RawRelationshipData
rawRelationshipData =
  oneOf
    [ Json.Decode.map Many (list resourceIdentifier)
    , Json.Decode.map One resourceIdentifier
    ]


resourceIdentifier : Decoder ResourceIdentifier
resourceIdentifier =
  decode ResourceIdentifier
    |> required "id" string
    |> required "type" string
