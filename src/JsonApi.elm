module JsonApi exposing
  ( attributes
  , primaryResource
  , primaryResourceCollection
  , relatedResource
  , relatedResourceCollection
  )

{-| Helper functions for dealing with Json Api payloads

# Common Helpers
@docs attributes, primaryResource, primaryResourceCollection, relatedResource, relatedResourceCollection

-}
import Dict
import JsonApi.Data exposing (..)
import JsonApi.OneOrMany as OneOrMany exposing (OneOrMany(..), extractOne, extractMany)
import List.Extra

{-| Pull the attributes off of a Resource, so that you don't have to do the
    destructuring yourself.
-}
attributes : Resource -> Attributes
attributes resource =
  let
    (Resource identifier object) = resource

  in
    object.attributes

{-| Retrieve the primary resource from a decoded Document.
    This function assumes a singular primary resource.
-}
primaryResource : Document -> Result String Resource
primaryResource doc =
  Result.map (hydrateResource doc.included) (extractOne doc.data)

{-| Retrieve the primary resource from a decoded Document. 
    This function assumes a singular primary resource.
-}
primaryResourceCollection : Document -> Result String (List Resource)
primaryResourceCollection doc =
  Result.map (List.map (hydrateResource doc.included)) (extractMany doc.data)


{-| Find a related resource.
    Will return an Err if a resource collection is found.
-}
relatedResource : String -> Resource -> Result String Resource
relatedResource relationshipName resource =
  (related relationshipName resource) `Result.andThen` extractOne

{-| Find a related collection of resources.
    Will return an Err if a single resource is found.
-}
relatedResourceCollection : String -> Resource -> Result String (List Resource)
relatedResourceCollection relationshipName resource =
  (related relationshipName resource) `Result.andThen` extractMany


related : String -> Resource -> Result String (OneOrMany Resource)
related relationshipName (Resource identifier resourceObject) =
  case Dict.get relationshipName (resourceObject.relationships) of
    Nothing ->
      Err ("Could not find a relationship with the name '" ++ relationshipName ++ "'")

    Just relationship ->
      case relationship.data of
        Nothing ->
          Err ("No resources found for the relationship '" ++ relationshipName ++ "'")

        Just resourceData ->
          Ok resourceData


hydrateData : List RawResource -> RawData -> Data
hydrateData includedData data =
  OneOrMany.map (hydrateResource includedData) data


hydrateResource : List RawResource -> RawResource -> Resource
hydrateResource includedData (RawResource resourceId rawResourceObject) =
  Resource resourceId
    { rawResourceObject
      | relationships = hydrateRelationships includedData rawResourceObject.relationships
    }


hydrateRelationships : List RawResource -> RawRelationships -> Relationships
hydrateRelationships includedData relationships =
  Dict.map (hydrateSingleRelationship includedData) relationships


hydrateSingleRelationship : List RawResource -> String -> RawRelationship -> Relationship
hydrateSingleRelationship includedData relationshipName relationship =
  case relationship.data of
    One relationshipData ->
      let
        maybeData =
          List.Extra.find
            (\(RawResource ident _) -> ident == relationshipData)
            includedData

        recursivelyHydratedMaybeData = Maybe.map (hydrateData includedData) (Maybe.map One maybeData)
      in
        { relationship | data = recursivelyHydratedMaybeData }

    Many relationshipDataList ->
      let
        hydratedRelationshipDataList =
          List.filter
            (\(RawResource ident _) -> List.member ident relationshipDataList)
            includedData

        recursivelyHydratedDataList = hydrateData includedData (Many hydratedRelationshipDataList)
      in
        { relationship | data = Just recursivelyHydratedDataList }


