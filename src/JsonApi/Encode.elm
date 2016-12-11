module JsonApi.Encode
    exposing
        ( clientResource
        )

import Json.Encode as Encode
import JsonApi.Data exposing (..)


{-| Functions for encoding JSON API resources to Json

@docs clientResource

-}
clientResource : ClientResource -> Encode.Value
clientResource resource =
    Encode.string "\n asdasd \n"
