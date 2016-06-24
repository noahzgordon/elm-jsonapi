module JsonApi.Documents
    exposing
        ( primaryResource
        , primaryResourceCollection
        , jsonapi
        )

{-| Helper functions for working with a full JsonApi Document

# Common Helpers
@docs primaryResource, primaryResourceCollection, jsonapi

-}

import Dict
import JsonApi.Data exposing (..)
import JsonApi.OneOrMany as OneOrMany exposing (OneOrMany(..), extractOne, extractMany)
import List.Extra


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


{-| Fetch information from the top-level 'jsonapi' object
-}
jsonapi : Document -> Maybe JsonApiObject
jsonapi doc =
    doc.jsonapi


hydratePrimaryResource : List RawResource -> RawResource -> Resource
hydratePrimaryResource relatedResources resource =
    let
        (RawResource id obj) =
            resource
    in
        Resource id obj (resource :: relatedResources)
