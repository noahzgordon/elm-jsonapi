module JsonApi.Data exposing (..)

import Dict exposing (Dict)
import Json.Decode
import JsonApi.OneOrMany exposing (OneOrMany)


type Document
    = Document DocumentObject


type alias DocumentObject =
    { data : OneOrMany RawResource
    , included : List RawResource
    , links : Links
    , jsonapi : Maybe JsonApiObject
    , meta : Meta
    }


type Resource
    = Resource ResourceIdentifier ResourceObject (List RawResource)


type ClientResource
    = ClientResource String (Maybe String) ResourceObject


type RawResource
    = RawResource ResourceIdentifier ResourceObject


type alias ResourceIdentifier =
    { id : String, resourceType : String }


type alias ResourceObject =
    { attributes : Attributes
    , relationships : Relationships
    , links : Links
    , meta : Meta
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
    Maybe Json.Decode.Value


type alias Meta =
    Maybe Json.Decode.Value


type alias Link =
    Maybe String


type alias ErrorLinks =
    { about : Maybe String }


type alias Source =
    { pointer : Maybe String
    , parameter : Maybe String
    }
