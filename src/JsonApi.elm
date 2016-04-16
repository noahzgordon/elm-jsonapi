module JsonApi (singletonPrimary, attributes, HydratedResource, HydratedRelationship, HydratedRelationships) where

{-| Library for decoding JSONAPI-compliant payloads

@docs singletonPrimary, attributes, HydratedResource, HydratedRelationship, HydratedRelationships
-}

import JsonApi.Decode exposing (..)
import Result exposing (Result)
import Dict exposing (Dict, get, map)


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
singletonPrimary : Document -> Result String HydratedResource
singletonPrimary doc =
  case doc.data of
    Singleton resource ->
      hydrateResource doc.included resource

    Collection _ ->
      Err "Expected a singleton primary resource but got a collection"


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


{-| Retrieve the attributes from a resource.
-}
attributes : Resource -> Attributes
attributes resource =
  resource.attributes
