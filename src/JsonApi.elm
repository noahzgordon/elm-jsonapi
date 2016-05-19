module JsonApi exposing (attributes, related)

{-| Helper functions for dealing with Json Api payloads

# Common Helpers
@docs attributes, related

-}
import Dict
import JsonApi.Data exposing (Resource(..), Attributes)
import JsonApi.OneOrMany exposing (OneOrMany(..))

{-| Pull the attributes off of a Resource, so that you don't have to do the
    destructuring yourself.
-}
attributes : Resource -> Attributes
attributes resource =
  let
    (Resource identifier object) = resource

  in
    object.attributes


{-| Find a related resource object or list of resource objects
-}
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
