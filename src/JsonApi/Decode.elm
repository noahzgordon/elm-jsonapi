module JsonApi.Decode (..) where

{-| Library for decoding JSONAPI-compliant payloads

@docs document
-}

import Json.Decode exposing (..)
import Json.Decode.Pipeline exposing (decode, required, optional, hardcoded)
import Result exposing (Result)
import Dict exposing (Dict, get, map)
import JsonApi.OneOrMany as OneOrMany exposing (OneOrMany(..))


{-| Represents a resource whose relationships have been hydrated with pointers to other resources.
-}
type alias HydratedResource =
  { id : String
  , resourceType : String
  , attributes : Attributes
  , relationships : HydratedRelationships
  , links : Links
  }


{-| A Dictionary with HydratedRelationship records as values.
-}
type alias HydratedRelationships =
  Dict String HydratedRelationship


{-| A relationships object whose data has been updated with full data from the 'included' resources,
rather than just containing 'id' and 'type'.
-}
type alias HydratedRelationship =
  { data : Data
  , links : Links
  , meta : Meta
  }


{-| Retrieve the primary resource from a JSONAPI payload. This function assumes a singular primary resource.
-}
primary : Json.Decode.Decoder (OneOrMany HydratedResource)
primary =
  Json.Decode.customDecoder document (\doc -> hydratePrimary doc)


hydratePrimary : Document -> Result String (OneOrMany HydratedResource)
hydratePrimary doc =
  OneOrMany.mapToResult (hydrateResource doc.included) doc.data


hydrateResource : List Resource -> Resource -> Result String HydratedResource
hydrateResource includedData resource =
  case hydrateRelationships includedData resource.relationships of
    Ok successfullyHydratedRelationships ->
      Ok { resource | relationships = successfullyHydratedRelationships }

    Err string ->
      Err string


hydrateRelationships : List Resource -> Relationships -> Result String HydratedRelationships
hydrateRelationships includedData relationships =
  Dict.foldl (hydrateSingleRelationship includedData) (Ok Dict.empty) relationships


hydrateSingleRelationship : List Resource -> String -> Relationship -> Result String HydratedRelationships -> Result String HydratedRelationships
hydrateSingleRelationship includedData key relationship newRelationshipsResult =
  case newRelationshipsResult of
    Ok newRelationships ->
      case buildHydratedRelationship includedData relationship of
        Ok hydratedRelationship ->
          Ok (Dict.insert key hydratedRelationship newRelationships)

        Err string ->
          Err string

    Err string ->
      Err string


buildHydratedRelationship : List Resource -> Relationship -> Result String HydratedRelationship
buildHydratedRelationship includedData relationship =
  case relationship.data of
    Singleton relationshipData ->
      let
        relatedId =
          relationshipData.id

        relatedType =
          relationshipData.resourceType

        maybeHydratedRelationshipData =
          List.head
            <| List.filter
                (\resource -> resource.id == relatedId && resource.resourceType == relatedType)
                includedData
      in
        case maybeHydratedRelationshipData of
          Just hydratedRelationshipData ->
            Ok { relationship | data = Singleton hydratedRelationshipData }

          Nothing ->
            Err ("Included resource with id " ++ relatedId ++ " and type " ++ relatedType ++ " could not be found")

    Collection relationshipDataList ->
      let
        relatedIds =
          List.map (\record -> record.id) relationshipDataList

        relatedTypes =
          List.map (\record -> record.resourceType) relationshipDataList

        hydratedRelationshipDataList =
          List.filter
            (\resource -> (List.member resource.id relatedIds) && (List.member resource.resourceType relatedTypes))
            includedData
      in
        Ok { relationship | data = Collection hydratedRelationshipDataList }


type alias Document =
  { data : Data
  , included : List Resource
  , links : Links
  , meta : Meta
  }


type alias Data =
  OneOrMany Resource


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


type alias RelationshipData =
  OneOrMany ResourceIdentifier


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
    [ Json.Decode.map Collection (list resource)
    , Json.Decode.map Singleton resource
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
    [ Json.Decode.map Collection (list resourceIdentifier)
    , Json.Decode.map Singleton resourceIdentifier
    ]


resourceIdentifier : Decoder ResourceIdentifier
resourceIdentifier =
  decode ResourceIdentifier
    |> required "id" string
    |> required "type" string
