module JsonApi.OneOrMany (..) where


type OneOrMany a
  = One a
  | Many (List a)


map : (a -> b) -> OneOrMany a -> OneOrMany b
map fn oneOrMany =
  case oneOrMany of
    One x ->
      One (fn x)

    Many xs ->
      Many (List.map fn xs)


mapToResult : (a -> Result String b) -> OneOrMany a -> Result String (OneOrMany b)
mapToResult fn oneOrMany =
  case oneOrMany of
    One x ->
      Result.map One (fn x)

    Many xs ->
      let
        foldFn x resultList =
          case fn x of
            Ok result ->
              Result.map ((::) result) resultList
            Err string ->
              Err string
      in
        Result.map Many (List.foldl foldFn (Ok []) xs)

-- (item -> result -> result) -> acc -> iter
