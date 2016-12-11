module JsonApi.Encode
    exposing
        ( clientResource
        )

{-| Functions for encoding JSON API resources to Json

@docs clientResource

-}

import Json.Encode as Encode
import JsonApi.Data exposing (..)
import Dict
import Tuple2
import JsonApi.OneOrMany as OneOrMany exposing (OneOrMany(..))


{-| Encode a resource constructed on the client to a JSON API-compliant value
    see: http://jsonapi.org/format/#crud-creating
-}
clientResource : ClientResource -> Encode.Value
clientResource (ClientResource id object) =
    let
        attributes =
            Maybe.withDefault (Encode.object []) object.attributes

        relationships =
            Dict.toList object.relationships
                |> List.map (Tuple2.map relationship)
                |> Encode.object
    in
        Encode.object
            [ ( "data"
              , Encode.object
                    [ ( "type", Encode.string id )
                    , ( "attributes", attributes )
                    , ( "relationships", relationships )
                    ]
              )
            ]


relationship : Relationship -> Encode.Value
relationship rel =
    let
        data =
            case (OneOrMany.map resourceIdentifier rel.data) of
                One value ->
                    value

                Many values ->
                    Encode.list values
    in
        Encode.object [ ( "data", data ) ]


resourceIdentifier : ResourceIdentifier -> Encode.Value
resourceIdentifier identifier =
    Encode.object
        [ ( "id", Encode.string identifier.id )
        , ( "type", Encode.string identifier.resourceType )
        ]
