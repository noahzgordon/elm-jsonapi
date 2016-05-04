module JsonApi.Decode (..) where

{-| Library for decoding JSONAPI-compliant payloads

@docs document
-}

import Json.Decode exposing (..)
import Json.Decode.Pipeline exposing (decode, required, optional, hardcoded)
import Result exposing (Result)
import Dict

import JsonApi.OneOrMany as OneOrMany exposing (OneOrMany(..))
import JsonApi.Data exposing (..)


{-| Retrieve the primary resource from a JSONAPI payload. This function assumes a singular primary resource.
-}
primary : Json.Decode.Decoder HydratedData
primary =
  Json.Decode.customDecoder document (\doc -> Ok (hydratePrimary doc))


hydratePrimary : Document -> HydratedData
hydratePrimary doc =
  hydrateData doc.included doc.data


hydrateData : List Resource -> Data -> HydratedData
hydrateData includedData data =
  OneOrMany.map (hydrateResource includedData) data


hydrateResource : List Resource -> Resource -> HydratedResource
hydrateResource includedData resource =
  HydratedResource
    { resource
      | relationships = hydrateRelationships includedData resource.relationships
    }


hydrateRelationships : List Resource -> Relationships -> HydratedRelationships
hydrateRelationships includedData relationships =
  Dict.map (hydrateSingleRelationship includedData) relationships


hydrateSingleRelationship : List Resource -> String -> Relationship -> HydratedRelationship
hydrateSingleRelationship includedData relationshipName relationship =
  case relationship.data of
    Singleton relationshipData ->
      let
        relatedId =
          relationshipData.id

        relatedType =
          relationshipData.resourceType

        maybeData =
          List.head
            <| List.filter
                (\resource -> resource.id == relatedId && resource.resourceType == relatedType)
                includedData

        recursivelyHydratedMaybeData = Maybe.map (hydrateData includedData) (Maybe.map Singleton maybeData)
      in
        { relationship | data = recursivelyHydratedMaybeData }

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

        recursivelyHydratedDataList = hydrateData includedData (Collection hydratedRelationshipDataList)
      in
        { relationship | data = Just recursivelyHydratedDataList }



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
