module Main exposing (main)

import Html exposing (text)
import Dict
import Json.Decode exposing (decodeString, decodeValue)
import JsonApi
import JsonApi.Decode
import JsonApi.Resources
import JsonApi.Documents
import Payloads


main =
  case getPayload of
    Ok document ->
      view document

    Err string ->
      text ("Something went wrong: " ++ string)


view document =
  let
    luke = JsonApi.Documents.primaryResource document
    parents = JsonApi.Resources.relatedResourceCollection "parents" luke
    sister = JsonApi.Resources.relatedResource "sister" luke
    brotherInLaw = JsonApi.Resources.relatedResource "husband" sister
  in
    text ("Hello! My name is " ++ nameFromResource luke)


getPayload : Result String JsonApi.Document
getPayload =
  decodeString JsonApi.Decode.document Payloads.user


nameFromResource : JsonApi.Resource -> String
nameFromResource resource =
  JsonApi.Resources.attributes resource
    |> Dict.get "first_name"
    |> Maybe.withDefault "<REDACTED>"
