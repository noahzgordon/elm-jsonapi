module JsonApi.Data where

import Dict exposing (Dict)
import Json.Decode
import JsonApi.OneOrMany exposing (OneOrMany)

{-| Represents a resource or resource collection whose relationships have been hydrated with pointers to other resources.
-}
type alias HydratedData =
  OneOrMany HydratedResource

{-| Represents a resource whose relationships have been hydrated with pointers to other resources.
-}
type HydratedResource = HydratedResource
  { id : String
  , resourceType : String
  , attributes : Attributes
  , relationships : HydratedRelationships
  , links : Links
  }


{-| A Dictionary with HydratedRelationship records as values.
-}
type alias HydratedRelationships =
  Dict String HydratedRelationship


{-| A relationships object whose data has been updated with full data from the 'included' resources,
rather than just containing 'id' and 'type'.
-}
type alias HydratedRelationship =
  { data : Maybe HydratedData
  , links : Links
  , meta : Meta
  }

type alias Document =
  { data : Data
  , included : List Resource
  , links : Links
  , meta : Meta
  }


type alias Data =
  OneOrMany Resource


type alias Resource =
  { id : String
  , resourceType : String
  , attributes : Attributes
  , relationships : Relationships
  , links : Links
  }


type alias Relationships =
  Dict String Relationship


type alias Relationship =
  { data : RelationshipData
  , links : Links
  , meta : Meta
  }


type alias RelationshipData =
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

