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
    (Resource _ object _) = resource

  in
    object.attributes

{-| Retrieve the primary resource from a decoded Document.
    This function assumes a singular primary resource.
-}
primaryResource : Document -> Result String Resource
primaryResource doc =
  Result.map (hydratePrimaryResource doc.included) (extractOne doc.data)

{-| Retrieve the primary resource from a decoded Document.
    This function assumes a singular primary resource.
-}
primaryResourceCollection : Document -> Result String (List Resource)
primaryResourceCollection doc =
  Result.map (List.map (hydratePrimaryResource doc.included)) (extractMany doc.data)


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
related relationshipName (Resource identifier resourceObject relatedResources) =
  case Dict.get relationshipName (resourceObject.relationships) of
    Nothing ->
      Err ("Could not find a relationship with the name '" ++ relationshipName ++ "'")

    Just relationship ->
      case relationship.data of
        One relIdentifier ->
          Result.map One (getRelatedResource relatedResources relIdentifier)

        Many relIdentifiers ->
          Result.map Many (getRelatedCollection relatedResources relIdentifiers)


getRelatedResource : List RawResource -> ResourceIdentifier -> Result String Resource
getRelatedResource relatedResources identifier =
  let
    compare (RawResource id _) =
      id == identifier

  in
    List.Extra.find compare relatedResources
      |> Maybe.map (hydrateResource relatedResources)
      |> Result.fromMaybe ("Could not find related resource with identifier" ++ toString identifier)


getRelatedCollection : List RawResource -> List ResourceIdentifier -> Result String (List Resource)
getRelatedCollection relatedResources identifiers =
  let
    compare (RawResource id _) =
      List.member id identifiers

  in
    List.filter compare relatedResources
      |> List.map (hydrateResource relatedResources)
      |> Ok


hydratePrimaryResource : List RawResource -> RawResource -> Resource
hydratePrimaryResource relatedResources resource =
  let
    (RawResource id obj) = resource

  in
    Resource id obj (resource :: relatedResources)

hydrateResource : List RawResource -> RawResource -> Resource
hydrateResource relatedResources (RawResource id obj) =
  Resource id obj relatedResources

