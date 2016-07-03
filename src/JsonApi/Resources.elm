module JsonApi.Resources
    exposing
        ( id
        , attributes
        , relatedResource
        , relatedResourceCollection
        , links
        , meta
        , Resource
        , Links
        , Meta
        )

{-| Helper functions for working with a single JsonApi Resource

# Common Helpers
@docs id, attributes, links, relatedResource, relatedResourceCollection, meta

# Data Types
@docs Resource, Links, Meta

-}

import Dict
import JsonApi.Data exposing (..)
import JsonApi.OneOrMany as OneOrMany exposing (OneOrMany(..), extractOne, extractMany)
import JsonApi.Data exposing (..)
import List.Extra


{-| Data type representing a single JsonApi resource.
-}
type alias Resource =
    JsonApi.Data.Resource


{-| Data type representing a JsonApi links object.
    See: jsonapi.org/format/#document-links
-}
type alias Links =
    JsonApi.Data.Links


{-| Data type representing a JsonApi meta object. Alias for Json.Encode.Value.
    See: jsonapi.org/format/#document-meta
-}
type alias Meta =
    JsonApi.Data.Meta


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


{-| Get the string ID of a Resource
-}
id : Resource -> String
id (Resource identifier _ _) =
    identifier.id


{-| Pull the attributes off of a Resource, so that you don't have to do the
    destructuring yourself.
-}
attributes : Resource -> Attributes
attributes (Resource _ object _) =
    object.attributes


{-| Pull the attributes off of a Resource.
-}
links : Resource -> Links
links (Resource _ object _) =
    object.links


{-| Pull the meta value off of a Resource.
-}
meta : Resource -> Meta
meta (Resource _ object _) =
    object.meta


{- Unexposed functions and types -}


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


hydrateResource : List RawResource -> RawResource -> Resource
hydrateResource relatedResources (RawResource id obj) =
    Resource id obj relatedResources
