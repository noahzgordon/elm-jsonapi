module JsonApi exposing (attributes, relatedResource, relatedResourceCollection)

{-| Helper functions for dealing with Json Api payloads

# Common Helpers
@docs attributes, relatedResource, relatedResourceCollection

-}
import Dict
import JsonApi.Data exposing (Resource(..), Attributes)
import JsonApi.OneOrMany exposing (OneOrMany(..), extractOne, extractMany)

{-| Pull the attributes off of a Resource, so that you don't have to do the
    destructuring yourself.
-}
attributes : Resource -> Attributes
attributes resource =
  let
    (Resource identifier object) = resource

  in
    object.attributes


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
