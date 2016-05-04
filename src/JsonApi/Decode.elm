module JsonApi.Decode (primary) where

{-| Library for decoding JSONAPI-compliant payloads

@docs primary
-}

import Json.Decode exposing (..)
import Json.Decode.Pipeline exposing (decode, required, optional, hardcoded)
import Result exposing (Result)
import Dict

import JsonApi.OneOrMany as OneOrMany exposing (OneOrMany(..))
import JsonApi.Data exposing (..)


{-| Retrieve the primary resource from a JSONAPI payload. This function assumes a singular primary resource.
-}
primary : Json.Decode.Decoder Data
primary =
  Json.Decode.customDecoder document (\doc -> Ok (hydratePrimary doc))


hydratePrimary : Document -> Data
hydratePrimary doc =
  hydrateData doc.included doc.data


hydrateData : List RawResource -> RawData -> Data
hydrateData includedData data =
  OneOrMany.map (hydrateResource includedData) data


hydrateResource : List RawResource -> RawResource -> Resource
hydrateResource includedData resource =
  Resource
    { resource
      | relationships = hydrateRelationships includedData resource.relationships
    }


hydrateRelationships : List RawResource -> RawRelationships -> Relationships
hydrateRelationships includedData relationships =
  Dict.map (hydrateSingleRelationship includedData) relationships


hydrateSingleRelationship : List RawResource -> String -> RawRelationship -> Relationship
hydrateSingleRelationship includedData relationshipName relationship =
  case relationship.data of
    One relationshipData ->
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

        recursivelyHydratedMaybeData = Maybe.map (hydrateData includedData) (Maybe.map One maybeData)
      in
        { relationship | data = recursivelyHydratedMaybeData }

    Many relationshipDataList ->
      let
        relatedIds =
          List.map (\record -> record.id) relationshipDataList

        relatedTypes =
          List.map (\record -> record.resourceType) relationshipDataList

        hydratedRelationshipDataList =
          List.filter
            (\resource -> (List.member resource.id relatedIds) && (List.member resource.resourceType relatedTypes))
            includedData

        recursivelyHydratedDataList = hydrateData includedData (Many hydratedRelationshipDataList)
      in
        { relationship | data = Just recursivelyHydratedDataList }



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
  decode RawResource
    |> required "id" string
    |> required "type" string
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
