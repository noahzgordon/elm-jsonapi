module JsonApi.Data exposing (..)

import Dict exposing (Dict)
import Json.Decode
import JsonApi.OneOrMany exposing (OneOrMany)


type alias Document =
    { data : OneOrMany RawResource
    , included : List RawResource
    , links : Links
    , jsonapi : Maybe JsonApiObject
    , meta : Meta
    }


type Resource
    = Resource ResourceIdentifier ResourceObject (List RawResource)


type RawResource
    = RawResource ResourceIdentifier ResourceObject


type alias ResourceIdentifier =
    { id : String, resourceType : String }


type alias ResourceObject =
    { attributes : Attributes
    , relationships : Relationships
    , links : Links
    }


type alias Relationships =
    Dict String Relationship


type alias Relationship =
    { data : OneOrMany ResourceIdentifier
    , links : Links
    , meta : Meta
    }


type alias Links =
    { self : Link
    , related : Link
    , first : Link
    , last : Link
    , prev : Link
    , next : Link
    }


type alias JsonApiObject =
    { version : Maybe String
    , meta : Meta
    }


emptyLinks : Links
emptyLinks =
    { self = Nothing
    , related = Nothing
    , first = Nothing
    , last = Nothing
    , prev = Nothing
    , next = Nothing
    }


type alias Attributes =
    Dict String Json.Decode.Value


type alias Meta =
    Maybe Json.Decode.Value


type alias Link =
    Maybe String
