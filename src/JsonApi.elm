module JsonApi
    exposing
        ( Document
        , Resource
        , Links
        , Meta
        )

{-| A library for processing and working with JSON API payloads.

# Generic Data Types
@docs Document, Resource, Links, Meta

-}

import JsonApi.Data


{-| Data type representing the entire JsonApi document.
-}
type alias Document =
    JsonApi.Data.Document


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
