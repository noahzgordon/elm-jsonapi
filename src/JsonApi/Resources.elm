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
        , build
        , withAttributes
        , withRelationship
        , withRelationships
        , withUuid
        )

{-| Helper functions for working with a single JsonApi Resource

# Common Helpers
@docs id, attributes, attribute, links, relatedResource, relatedResourceCollection,
      meta, relatedLinks, relatedMeta, build, withAttributes, withRelationship, withRelationships, withUuid
-}

import Dict
import Json.Encode as Encode
import Json.Decode as Decode exposing (Decoder, decodeValue, field)
import JsonApi.Data exposing (..)
import JsonApi.OneOrMany as OneOrMany exposing (OneOrMany(..), extractOne, extractMany)
import JsonApi.Data exposing (..)
import List.Extra
import Uuid.Barebones exposing (isValidUuid)


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
    attributes (field key Decode.value) resource
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


{-| Construct a ClientResource instance with the supplied type.
    ClientResources are like Resources but without an 'id' field or related resources.
    Use them to represent new Resources that you want to POST to a JSON API server.
-}
build : String -> ClientResource
build resourceType =
    ClientResource resourceType
        Nothing
        { attributes = Nothing
        , relationships = Dict.empty
        , links = emptyLinks
        , meta = Nothing
        }


{-| Add a client-generated UUID to the resource. MUST be a valid Uuid in the
    canonical representation xxxxxxxx-xxxx-Axxx-Yxxx-xxxxxxxxxxxx where A is
    the version number between [1-5] and Y is in the range [8-B].

    I recommend using http://package.elm-lang.org/packages/danyx23/elm-uuid/2.0.2/Uuid
    to general a valid UUID.
-}
withUuid : String -> ClientResource -> Result String ClientResource
withUuid uuid (ClientResource resourceType id obj) =
    if isValidUuid uuid then
        Ok (ClientResource resourceType (Just uuid) obj)
    else
        Err "Uuid is not canonically valid"


{-| Add a list of string-value pairs as attributes to a ClientResource
-}
withAttributes : List ( String, Encode.Value ) -> ClientResource -> ClientResource
withAttributes attrs (ClientResource resourceType id obj) =
    let
        newAttrs =
            case obj.attributes of
                Just oldAttrs ->
                    oldAttrs
                        |> decodeValue (Decode.dict Decode.value)
                        |> Result.map Dict.toList
                        |> Result.map (List.append attrs)
                        |> Result.map Encode.object
                        |> Result.toMaybe

                Nothing ->
                    Just (Encode.object attrs)
    in
        ClientResource resourceType id { obj | attributes = newAttrs }


{-| Add a relationship with a single related resource to a ClientResource
-}
withRelationship : String -> ResourceIdentifier -> ClientResource -> ClientResource
withRelationship name identifier (ClientResource resourceType id obj) =
    let
        newRelationships =
            { data = OneOrMany.One identifier, links = emptyLinks, meta = Nothing }
    in
        ClientResource resourceType id { obj | relationships = Dict.insert name newRelationships obj.relationships }


{-| Add a relationship with a collection of related resources to a ClientResource
-}
withRelationships : String -> List ResourceIdentifier -> ClientResource -> ClientResource
withRelationships name identifiers (ClientResource resourceType id obj) =
    let
        newRelationships =
            { data = OneOrMany.Many identifiers, links = emptyLinks, meta = Nothing }
    in
        ClientResource resourceType id { obj | relationships = Dict.insert name newRelationships obj.relationships }



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
