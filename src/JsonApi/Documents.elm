module JsonApi.Documents
    exposing
        ( primaryResource
        , primaryResourceCollection
        , jsonapi
        , links
        , Document
        , Links
        , Meta
        )

{-| Helper functions for working with a full JsonApi Document

# Common Helpers
@docs links, jsonapi, primaryResource, primaryResourceCollection, meta

# Data Types
@docs Document, Links, Meta

-}

import Dict
import JsonApi.Data exposing (..)
import JsonApi.OneOrMany as OneOrMany exposing (OneOrMany(..), extractOne, extractMany)
import List.Extra


{-| Data type representing the entire JsonApi document.
-}
type alias Document =
    JsonApi.Data.Document


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


{-| Retrieve the primary resource from a decoded Document.
    This function assumes a singular primary resource.
-}
primaryResource : Document -> Result String Resource
primaryResource (Document doc) =
    Result.map (hydratePrimaryResource doc.included) (extractOne doc.data)


{-| Retrieve the primary resource from a decoded Document.
    This function assumes a singular primary resource.
-}
primaryResourceCollection : Document -> Result String (List Resource)
primaryResourceCollection (Document doc) =
    Result.map (List.map (hydratePrimaryResource doc.included)) (extractMany doc.data)


{-| Fetch the top-level links object from the document.
-}
links : Document -> Links
links (Document doc) =
    doc.links


{-| Fetch the top-level meta object from the document.
-}
meta : Document -> Meta
meta (Document doc) =
    doc.meta


{-| Fetch information from the top-level 'jsonapi' object
-}
jsonapi : Document -> Maybe JsonApiObject
jsonapi (Document doc) =
    doc.jsonapi


{- Unexposed functions -}


hydratePrimaryResource : List RawResource -> RawResource -> Resource
hydratePrimaryResource relatedResources resource =
    let
        (RawResource id obj) =
            resource
    in
        Resource id obj (resource :: relatedResources)
