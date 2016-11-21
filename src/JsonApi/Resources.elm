module JsonApi.Resources
    exposing
        ( id
        , attributes
        , attribute
        , relatedResource
        , relatedResourceCollection
        , links
        , meta
        , relatedLinks
        , relatedMeta
        )

{-| Helper functions for working with a single JsonApi Resource

# Common Helpers
@docs id, attributes, attribute, links, relatedResource, relatedResourceCollection, meta, relatedLinks, relatedMeta

-}

import Dict
import Json.Encode
import Json.Decode exposing (Decoder, decodeValue, field)
import JsonApi.Data exposing (..)
import JsonApi.OneOrMany as OneOrMany exposing (OneOrMany(..), extractOne, extractMany)
import JsonApi.Data exposing (..)
import List.Extra


{-| Find a related resource.
    Will return an Err if a resource collection is found.
-}
relatedResource : String -> Resource -> Result String Resource
relatedResource relationshipName resource =
    (related relationshipName resource)
        |> Result.andThen extractOne


{-| Find a related collection of resources.
    Will return an Err if a single resource is found.
-}
relatedResourceCollection : String -> Resource -> Result String (List Resource)
relatedResourceCollection relationshipName resource =
    (related relationshipName resource)
        |> Result.andThen extractMany


{-| Retreive the links from a relationship.
    Will return an Err if the relationship does not exist.
-}
relatedLinks : String -> Resource -> Result String Links
relatedLinks relationshipName resource =
    getRelationship relationshipName resource
        |> Result.map .links


{-| Retreive the meta information from a relationship.
    Will return an Err if the relationship does not exist.
-}
relatedMeta : String -> Resource -> Result String Meta
relatedMeta relationshipName resource =
    getRelationship relationshipName resource
        |> Result.map .meta


{-| Get the string ID of a Resource
-}
id : Resource -> String
id (Resource identifier _ _) =
    identifier.id


{-| Serialize the attributes of a Resource. Because the attributes are unstructured,
    you must provide a Json Decoder to convert them into a type that you define.
-}
attributes : Decoder a -> Resource -> Result String a
attributes decoder (Resource _ object _) =
    case object.attributes of
        Just attrs ->
            decodeValue decoder attrs

        Nothing ->
            Err "No attributes key found for resource"


{-| Serialize a single attributes of a Resource. You must provide the string key of the attribute
    and a Json Decoder to convert the attribute into a type that you define.
-}
attribute : String -> Decoder a -> Resource -> Result String a
attribute key decoder resource =
    attributes (field key Json.Decode.value) resource
        |> Result.andThen (decodeValue decoder)


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
related relationshipName resource =
    getRelationship relationshipName resource
        |> Result.andThen (extractRelationshipData resource)


getRelationship : String -> Resource -> Result String Relationship
getRelationship name (Resource _ object _) =
    Dict.get name object.relationships
        |> Result.fromMaybe ("Could not find a relationship with the name '" ++ name ++ "'")


extractRelationshipData : Resource -> Relationship -> Result String (OneOrMany Resource)
extractRelationshipData (Resource relIdentifier _ relatedResources) relationship =
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
