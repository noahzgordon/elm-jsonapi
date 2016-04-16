module JsonApi.Decode (..) where

{-| Library for decoding JSONAPI-compliant payloads

@docs document
-}

import Json.Decode exposing (..)
import Json.Decode.Pipeline exposing (decode, required, optional, hardcoded)
import Dict exposing (Dict)


type alias Document =
  { data : Data
  , included : List Resource
  , links : Links
  , meta : Meta
  }


type alias Data =
  SingletonOrCollection Resource


type alias Resource =
  { id : String
  , resourceType : String
  , attributes : Attributes
  , relationships : Relationships
  , links : Links
  }


type alias Relationships =
  Dict String Relationship


type alias Relationship =
  { data : RelationshipData
  , links : Links
  , meta : Meta
  }


type SingletonOrCollection a
  = Singleton a
  | Collection (List a)


type alias RelationshipData =
  SingletonOrCollection ResourceIdentifier


type alias ResourceIdentifier =
  { id : String, resourceType : String }


type alias Links =
  { self : Link
  , related : Link
  , first : Link
  , last : Link
  , prev : Link
  , next : Link
  }


emptyLinks : Links
emptyLinks =
  { self = Nothing
  , related = Nothing
  , first = Nothing
  , last = Nothing
  , prev = Nothing
  , next = Nothing
  }


type alias Attributes =
  Dict String Value


type alias Meta =
  Maybe Value


type alias Link =
  Maybe String


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


data : Decoder Data
data =
  oneOf
    [ map Collection (list resource)
    , map Singleton resource
    ]


resource : Decoder Resource
resource =
  decode Resource
    |> required "id" string
    |> required "type" string
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


relationshipData : Decoder RelationshipData
relationshipData =
  oneOf
    [ map Collection (list resourceIdentifier)
    , map Singleton resourceIdentifier
    ]


resourceIdentifier : Decoder ResourceIdentifier
resourceIdentifier =
  decode ResourceIdentifier
    |> required "id" string
    |> required "type" string
