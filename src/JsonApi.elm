module JsonApi
    exposing
        ( Document
        , Resource
        , Links
        , Meta
        , ErrorObject
        )

{-| A library for processing and working with JSON API payloads.

# Generic Data Types
@docs Document, Resource, Links, Meta, ErrorObject

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


{-| Data type describing the types of problems that can be encountered when processing a JSON API payload.

+ BadFormat: The JSON API payload received from the server is formatted incorrectly.
+ ServerProblem: A problem was encountered on the server and reported in the document's top-level 'errors' list.

-}
type alias ErrorObject =
    { id : Maybe String
    , links : Maybe JsonApi.Data.ErrorLinks
    , status : Maybe String
    , code : Maybe String
    , title : Maybe String
    , detail : Maybe String
    , source : Maybe JsonApi.Data.Source
    , meta : Meta
    }

