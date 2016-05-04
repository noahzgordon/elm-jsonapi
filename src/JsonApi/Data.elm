module JsonApi.Data where

import Dict exposing (Dict)
import Json.Decode
import JsonApi.OneOrMany exposing (OneOrMany)

type alias Data =
  OneOrMany Resource

type Resource = Resource
  { id : String
  , resourceType : String
  , attributes : Attributes
  , relationships : Relationships
  , links : Links
  }


type alias Relationships =
  Dict String Relationship


type alias Relationship =
  { data : Maybe Data
  , links : Links
  , meta : Meta
  }


{- Raw data types; not exposed -}

type alias Document =
  { data : RawData
  , included : List RawResource
  , links : Links
  , meta : Meta
  }


type alias RawData =
  OneOrMany RawResource


type alias RawResource =
  { id : String
  , resourceType : String
  , attributes : Attributes
  , relationships : RawRelationships
  , links : Links
  }


type alias RawRelationships =
  Dict String RawRelationship


type alias RawRelationship =
  { data : RawRelationshipData
  , links : Links
  , meta : Meta
  }


type alias RawRelationshipData =
  OneOrMany ResourceIdentifier


type alias ResourceIdentifier =
  { id : String, resourceType : String }


type alias Links =
  { self : Link
  , related : Link
  , first : Link
  , last : Link
  , prev : Link
  , next : Link
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

