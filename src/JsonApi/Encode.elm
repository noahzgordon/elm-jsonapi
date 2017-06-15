module JsonApi.Encode
    exposing
        ( clientResource
        , resource
        )

{-| Functions for encoding JSON API resources to Json

@docs clientResource, resource

-}

import Json.Encode as Encode
import JsonApi.Data exposing (..)
import Dict
import Tuple2
import JsonApi.OneOrMany as OneOrMany exposing (OneOrMany(..))


{-| Encode a resource fetched from the server to a JSON API-compliant value
    see: http://jsonapi.org/format/#crud-updating
-}
resource : Resource -> Encode.Value
resource (Resource identifier object _) =
    [ ( "id", Encode.string identifier.id )
    , ( "type", Encode.string identifier.resourceType )
    ]
        ++ resourceObjectFields object
        |> Encode.object
        |> (\data -> Encode.object [ ( "data", data ) ])


{-| Encode a resource constructed on the client to a JSON API-compliant value
    see: http://jsonapi.org/format/#crud-creating
-}
clientResource : ClientResource -> Encode.Value
clientResource (ClientResource resourceType id object) =
    let
        typeFields =
            [ ( "type", Encode.string resourceType ) ]

        idFields =
            id
                |> Maybe.map (\i -> [ ( "id", Encode.string i ) ])
                |> Maybe.withDefault []
    in
        Encode.object
            [ ( "data"
              , Encode.object (typeFields ++ idFields ++ resourceObjectFields object)
              )
            ]


resourceObjectFields : ResourceObject -> List ( String, Encode.Value )
resourceObjectFields object =
    [ ( "attributes"
      , Maybe.withDefault (Encode.object []) object.attributes
      )
    , ( "relationships"
      , Dict.toList object.relationships
            |> List.map (Tuple2.map relationship)
            |> Encode.object
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
