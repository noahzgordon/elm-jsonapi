module JsonApi.OneOrMany exposing (OneOrMany(..), extractMany, extractOne, map)


type OneOrMany a
    = One (Maybe a)
    | Many (List a)


map : (a -> b) -> OneOrMany a -> OneOrMany b
map fn oneOrMany =
    case oneOrMany of
        One x ->
            One (Maybe.map fn x)

        Many xs ->
            Many (List.map fn xs)


extractOne : OneOrMany a -> Result String (Maybe a)
extractOne oneOrMany =
    case oneOrMany of
        One x ->
            Ok x

        Many xs ->
            Err "Expected a singleton resource, got a collection"


extractMany : OneOrMany a -> Result String (List a)
extractMany oneOrMany =
    case oneOrMany of
        One x ->
            Err "Expected a collection of resources, got a singleton"

        Many xs ->
            Ok xs
