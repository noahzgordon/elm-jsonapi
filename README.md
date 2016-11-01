# elm-jsonapi

elm-jsonapi decodes any JSON API compliant payload and provides helper functions for working with the results.

This library only provides base functionality for decoding payloads and working with the results. A more sophisticated wrapper which includes content negotation with servers can be found [here](https://github.com/noahzgordon/elm-jsonapi-http/tree/1.0.2).

See the documentation at: http://package.elm-lang.org/packages/noahzgordon/elm-jsonapi/latest

```elm
import Http
import Json.Decode exposing ((:=))
import JsonApi
import JsonApi.Decode
import JsonApi.Resources
import JsonApi.Documents
import Task exposing (..)


type alias User =
  { username : String
  , email : String
  }


userDecoder : Json.Decode.Decoder User
userDecoder =
  Json.Decode.object2
    ("username" := Json.Decode.string)
    ("email" := Json.Decode.string)


getUserResource : String -> Task Http.Error (JsonApi.Document)
getUserResource query =
    Http.get JsonApi.Decode.document ("http://www.jsonapi-compliant-server.com/users/" ++ query)


extractUsername : JsonApi.Document -> Result String User
extractUsername doc =
  JsonApi.Documents.primaryResource doc
    `Result.andThen` (JsonApi.Resources.attributes userDecoder)
```

## Known Issues
+ Links objects are unsupported. Links will only be captured if delivered as string values.
+ There is no dedicated type for Resource Identifiers. If your document's primary data is composed of Resource Identifiers, they will be represented as Resources without attributes or relationships.

## contributing

elm-jsonapi is currently under development. I use waffle.io and Github Issues to track new features and bugs. if there's a feature you'd like to see, please
[submit an issue](https://github.com/noahzgordon/elm-jsonapi/issues/new)! 

if you'd like to contribute yourself, please reach out to me or submit a pull request for the relevant issue.

[![Stories in Ready](https://badge.waffle.io/noahzgordon/elm-jsonapi.png?label=ready&title=Ready)](http://waffle.io/noahzgordon/elm-jsonapi)
