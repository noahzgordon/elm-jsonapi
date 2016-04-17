module JsonApi.OneOrMany (..) where


type OneOrMany a
  = Singleton a
  | Collection (List a)


map : (a -> b) -> OneOrMany a -> OneOrMany b
map fn oneOrMany =
  case oneOrMany of
    Singleton x ->
      Singleton (fn x)

    Collection xs ->
      Collection (List.map fn xs)


mapToResult : (a -> Result String b) -> OneOrMany a -> Result String (OneOrMany b)
mapToResult fn oneOrMany =
  case oneOrMany of
    Singleton x ->
      Result.map Singleton (fn x)

    Collection xs ->
      let
        foldFn x resultList =
          case fn x of
            Ok result ->
              Result.map ((::) result) resultList
            Err string ->
              Err string
      in
        Result.map Collection (List.foldl foldFn (Ok []) xs)

-- (item -> result -> result) -> acc -> iter
