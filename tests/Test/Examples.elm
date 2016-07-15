module Test.Examples exposing (..)

{- example payload copied from JsonApi official website: http://jsonapi.org/ -}


validPayload : String
validPayload =
    """
    {
      "jsonapi": {
        "version": "1.0",
        "meta": { "foo": "bar" }
      },
      "links": {
        "self": "http://example.com/articles",
        "next": "http://example.com/articles?page[offset]=2",
        "last": "http://example.com/articles?page[offset]=10"
      },
      "data": [{
        "type": "articles",
        "id": "1",
        "attributes": {
          "title": "JSON API paints my bikeshed!"
        },
        "relationships": {
          "author": {
            "links": {
              "self": "http://example.com/articles/1/relationships/author",
              "related": "http://example.com/articles/1/author"
            },
            "data": { "type": "people", "id": "9" }
          },
          "comments": {
            "links": {
              "self": "http://example.com/articles/1/relationships/comments",
              "related": "http://example.com/articles/1/comments"
            },
            "data": [
              { "type": "comments", "id": "5" },
              { "type": "comments", "id": "12" }
            ]
          }
        },
        "links": {
          "self": "http://example.com/articles/1"
        }
      }],
      "included": [{
        "type": "people",
        "id": "9",
        "attributes": {
          "first-name": "Dan",
          "last-name": "Gebhardt",
          "twitter": "dgeb"
        },
        "links": {
          "self": "http://example.com/people/9"
        }
      }, {
        "type": "comments",
        "id": "5",
        "attributes": {
          "body": "First!"
        },
        "relationships": {
          "author": {
            "data": { "type": "people", "id": "2" }
          }
        },
        "links": {
          "self": "http://example.com/comments/5"
        }
      }, {
        "type": "comments",
        "id": "12",
        "attributes": {
          "body": "I like XML better"
        },
        "relationships": {
          "author": {
            "data": { "type": "people", "id": "9" }
          }
        },
        "links": {
          "self": "http://example.com/comments/12"
        }
      }]
    }
  """


invalidPayload : String
invalidPayload =
    """
    {
      "data": [{
        "tpe": "articles",
        "id": "1",
      }]
    }
  """


recursivePayload : String
recursivePayload =
    """
    {
      "data": {
        "type": "articles",
        "id": "1",
        "attributes": {
          "title": "JSON API paints my bikeshed!"
        },
        "relationships": {
          "author": {
            "data": { "type": "people", "id": "9" }
          }
        }
      },
      "included": [{
        "type": "people",
        "id": "9",
        "attributes": {
          "first-name": "Dan",
          "last-name": "Gebhardt",
          "twitter": "dgeb"
        },
        "relationships": {
          "article": {
            "data": { "type": "articles", "id": "1" }
          }
        }
      }]
    }
  """


payloadWithErrors : String
payloadWithErrors =
    """
    {
      "errors": [
        {
          "id": "123",
          "links": {
            "about": "something/happened"
          },
          "status": "500",
          "code": "12345",
          "title": "Something Happened",
          "detail": "I'm not really sure what happened",
          "source": {
            "pointer": "/foo/0"
          }
        }
      ]
    }
  """

payloadWithResourceIdentifiers : String
payloadWithResourceIdentifiers =
    """
    {
      "data": {
        "type": "articles",
        "id": "2",
        "meta": "this is the second article"
      }
    }
  """
