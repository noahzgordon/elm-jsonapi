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
    |> required "data" data
    |> optional "included" (list resource) []
    |> optional "links" links emptyLinks
    |> optional "meta" meta Nothing


meta : Decoder Meta
meta =
  maybe value


data : Decoder (OneOrMany RawResource)
data =
  oneOf
    [ Json.Decode.map Many (list resource)
    , Json.Decode.map One resource
    ]


resource : Decoder RawResource
resource =
  object2 RawResource resourceIdentifier resourceObject


resourceObject : Decoder ResourceObject
resourceObject =
  decode ResourceObject
    |> optional "attributes" attributes Dict.empty
    |> optional "relationships" relationships Dict.empty
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
