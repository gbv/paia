# Introduction

{ABSTRACT}


## Synopsis

PAIA consists of two independent parts:

* **[PAIA core]** defines six basic [API methods] to look up loaned and reserved
  [items], to [request] and [cancel] loans and reservations, and to look up
  [fees], [messages], and general [patron] information.

* **[PAIA auth]** defines three authentication [API methods] ([login],
  [logout], and password [change]) to get or invalidate an [access token], and to
  modify credentials.

Authentication in PAIA is based on **OAuth 2.0** ([RFC 6749]) with bearer
tokens ([RFC 6750]) over HTTPS ([RFC 2818]).


## Status of this document

This specification has been created collaboratively based on use cases and
taking into account existing related standards and products of integrated
library systems (ILS), such as NISO Circulation Interchange Protocol (NCIP),
SIP2, \[X]SLNP,[^SLNP] DLF-ILS recommendations, and VuFind ILS.

[^SLNP]: The Simple Library Network Protocol (SLNP) and its variant XSLNP is an
  internal protocol of the the SISIS-Sunrise™ library system, providing access
  to patron information, among other functionality. OCLC does not allow
  publication of the specification or public use of SLNP.

All sources and updates can be found in a public git repository at
<http://github.com/gbv/paia>. See the [list of releases](#releases) at
<https://github.com/gbv/paia/releases> for functional changes. The master file
[paia.md](https://github.com/gbv/paia/blob/master/paia.md) is written in
[Pandoc’s Markdown].  HTML version of the specification is generated from the
master file with [makespec](https://github.com/jakobib/makespec). The
specification can be distributed freely under the terms of CC-BY-SA.

Additional information and references about PAIA can be found in the public
PAIA Wiki at <https://github.com/gbv/paia/wiki>.

[Pandoc’s Markdown]: http://johnmacfarlane.net/pandoc/demo/example9/pandocs-markdown.html


## Conformance requirements

The key words "MUST", "MUST NOT", "REQUIRED", "SHALL", "SHALL NOT", "SHOULD",
"SHOULD NOT", "RECOMMENDED", "MAY", and "OPTIONAL" in this document are to be
interpreted as described in [RFC 2119].

A PAIA server MUST implement [PAIA core] and it MAY implement [PAIA auth].  If
PAIA auth is not implemented, another way SHOULD BE documented to distribute
patron identifiers and access tokens. A PAIA server MAY support only a subset
of methods but it MUST return a valid response or an [error response] on every
method request, as defined in this document.


[PAIA core]: #paia-core
[PAIA auth]: #paia-auth
[patron]: #patron
[update patron]: #update-patron
[items]: #items
[renew]: #renew
[request]: #request
[cancel]: #cancel
[fees]: #fees
[messages]: #messages
[delete messages]: #delete-messages
[login]: #login
[logout]: #logout
[change]: #change

[access token]: #access-tokens-and-scopes
[scopes]: #access-token-and-scopes
[access tokens and scopes]: #access-tokens-and-scopes
[request error]: #request-errors


# Basics

## API methods

Each API method is accessed at a unique URL with a HTTP verb GET, POST, or PATCH:

[PAIA core]                                                                 [PAIA auth]
--------------------------------------------------------------------------- --------------------------------------
  [GET](#patron)/[PATCH](#update-patron) patron: general patron information POST [login]: get access token
  GET [items]: current loans, reservations, …                               POST [logout]: invalidate access token
  POST [request]: new reservation, delivery, …                              POST [change]: modify credentials
  POST [renew]: existing loans, reservations, …
  POST [cancel]: requests, reservations, …
  GET [fees]: paid and open charges
  [GET](#messages)/[DELETE](#delete-messages): individual patron messages
--------------------------------------------------------------------------- --------------------------------------

All supported API method URLs MUST also be accessible with HTTP verb OPTIONS.
Unsupported API methods MUST result in a [request error] with error code 501.
All API methods with HTTP verb GET MAY also be accessible with HTTP verb HEAD.

API method URLs share a common base URL for PAIA core methods and common base
URL for PAIA auth methods.  A server SHOULD NOT provide additional methods at
these base URLs and it MUST NOT propagate additional methods at these base URLs
as belonging to PAIA.

Base URLs of PAIA auth and PAIA core are not required to share a common host,
nor to include the URL path `core/` or `auth/`. In the following, the base URL
<https://example.org/core/> is used for PAIA core and
<https://example.org/auth/> for PAIA auth.

For security reasons, PAIA methods MUST be requested via HTTPS only. A PAIA
client MUST NOT ignore SSL certificate errors; otherwise access token (PAIA
core) or even password (PAIA auth) are compromised by the client.


## Access tokens and scopes

All PAIA API methods, except PAI auth [login] and HTTP OPTIONS requests require
an **access token** as a special request parameter. The access token is a so
called bearer token as described in [RFC 6750]. The access token can be sent
either as a URL query parameter or in an HTTP header. For instance the
following requests both get information about patron `123` with access token
`vF9dft4qmT`:

    curl -H "Authorization: Bearer vF9dft4qmT" https://example.org/core/123
    curl -H https://example.org/core/123?access_token=vF9dft4qmT

An access token is valid for a limited set of actions, referred to as
**scope**.  The following scopes are possible for PAIA core:

read_patron
  : Get patron information by the [patron] method.

update_patron / update_patron_name / update_patron_email / update_patron_address
  : Update parts of the patron information by the [update patron] method.

read_items
  : Get a patron’s item information by the [items] method.

write_items
  : Request, renew, and cancel items by the [request], [renew], and
    [cancel] methods.

read_fees
  : Get fees of a patron by the [fees] method.

read_messages
  : Get messages to a patron by the [messages] method.

delete_messages
  : Delete messages to a patron listed by the [messages] method.

For instance a particular token with scopes `read_patron` and `read_items` may
be used for read-only access to information about a patron, including its
loans and requested items but not its fees.

For PAIA auth there is an additional scope:

change_password
  : Change the password of a patron with the PAIA auth [change] method.

A PAIA auth server MAY support additional scopes to share an access token with
other services.


## Request and response format

Each API method call expects a set of request parameters, given as [URL query
fields], [HTTP headers], or [HTTP message body] and return a JSON object. Most
parts of PAIA core request parameters and JSON response can be mapped to RDF as
defined by the [PAIA Ontology].

Request parameters and fields of response objects are defined in this document
with:

* the **name** of the parameter/field
* the **ocurrence** (occ) of the parameter/field being one of
    * `0..1` (optional, non repeatable)
    * `1..1` (mandatory, non repeatable)
    * `1..n` (mandatory, repeatable)
    * `0..n` (optional, repeatable)
* the **data type** of the parameter/field
* a short description

Simple parameter names and response fields consist of lowercase letters `a-z`
only.

Repeatable response fields are encoded as JSON arrays with irrelevant order,
for instance:

~~~~ {.json}
{ "fee" : [ { ... }, { ... } ] }
~~~~

Hierarchical JSON structures in this document are referenced with a dot (`.`)
as separator. For instance the subfield/parameter `item` of the `doc` element
is referenced as `doc.item` and refers to the following JSON structure:

~~~~ {.json}
{ "doc" : [ { "item" : "..." } ] }
~~~~


## URL query fields

The following special request parameters can be added to any request as URL
query fields:

access_token
  : An [access token] can be sent either as URL query parameter or as HTTP
    request header.

callback
  : A JavaScript callback method name to return JSONP instead of JSON. The
    callback MUST only contain alphanumeric characters and underscores.

suppress_response_codes
  : If this parameter is present, *all* responses MUST be returned with a
    200 OK status code, even [request errors](#request-errors).


## HTTP headers

### Request headers {.unnumbered}

The following HTTP request headers SHOULD or MAY be sent by PAIA clients in
particular:

User-Agent
  : SHOULD be sent with an appropriate client name and version number

Accept
  : SHOULD be sent with value `application/json`

Authorization
  : MAY be sent to provide an [access token] or client credentials ([login])

Accept-Language
  : MAY be sent to indicate preferred languages of textual response fields

Content-Type
  : SHOULD be sent for HTTP POST with value `application/json` or
    for PAIA core and `application/x-www-form-urlencoded` for PAIA auth.

A OPTIONS preflight request for Cross-Origin Resource Sharing (CORS) MUST
include the cross-origin request headers:

Origin
  : Where the cross-origin request originates from

Access-Control-Request-Method
  : The HTTP verb of the actual request (GET or POST)

Access-Control-Request-Headers
  : The value `Authorization` if access tokens are sent as HTTP headers

Note that PAIA specification does not require clients to respect CORS rules.
CORS preflight requests in browsers can be avoided by using request format
`application/x-www-form-urlencoded` and omitting the request headers `Accept`
and `Authorization`.

### Response headers {.unnumbered}

PAIA core and PAIA auth servers SHOULD include the following HTTP response
headers:

Content-Language
  : The language of textual response fields

X-OAuth-Scopes
  : A space-separated list of [scopes], the current token has authorized,
    not limited to PAIA scopes. The `change_password` scope MAY be omitted
    in PAIA core responses.

X-Accepted-OAuth-Scopes
  : A space-separated list of [scopes], the current method checks for

Access-Control-Expose-Headers
  : The value `X-OAuth-Scopes X-Accepted-OAuth-Scopes`

Access-Control-Allow-Origin
  : The value `*` or another origin domain in response to a `Origin` request
    header.

WWW-Authenticate
  : The value `Bearer` for [request errors](#request-errors) with status 401

Allow
  : A list of supported HTTP verbs (e.g. `GET, HEAD, OPTIONS`) for
    [request errors](#request-errors) with status 405

PAIA core and PAIA auth servers MUST include the following HTTP response
headers:

Content-Type
  : The value `application/json` or `application/json; charset=utf-8` for
    JSON response; the value `application/javascript` or
    `application/javascript; charset=utf-8` for JSONP response

X-PAIA-Version
  : The version of PAIA specification which the server was checked against.

Access-Control-Allow-Headers
  : In response to a HTTP OPTIONS request this header MUST included the
    values `Content-Type`, `Authorization`, and `Accept-Language`

## HTTP message body

All POST and PATCH requests MUST include a HTTP message body.

* For [PAIA core] the message body MUST be sent in JSON format with content type
  `application/json`. A PAIA core server MAY also support message body as URL
  encoded query string.

* For [PAIA auth] the message body MUST be sent as URL encoded query string
  with content type `application/x-www-form-urlencoded`. A PAIA auth server
  MAY also support message body in JSON.

A PAIA Server MUST also accept the explicit charset UTF8 (content type
`application/json; charset=utf-8` or `application/x-www-form-urlencoded;
charset=utf-8`). A PAIA Server MAY support additional request charsets such as
ISO-8859-1.

## Request errors

[error response]: #request-errors

Malformed requests, failed authentication, unsupported methods, and unexpected
server errors such as backend downtime etc. MUST result in an error response.
An error response is returned with an HTTP status code 4xx (client error) or
5xx (server error) as defined in [RFC 2616], unless the request parameter
`suppress_response_codes` is given.

[Document errors] MUST NOT result in a request error but they are part of a
normal response.

The response body of a request error is a JSON object with the following fields
(compatible with OAuth error response):

 name                occ    data type             description
------------------- ------ --------------------- -----------------------------------------
 error               1..1   string                alphanumerical error code
 code                0..1   nonnegative integer   HTTP status error code
 error_description   0..1   string                Human-readable error description
 error_uri           0..1   string                Human-readable web page about the error
------------------- ------ --------------------- -----------------------------------------

The `code` field is REQUIRED with request parameter `suppress_response_codes`
in PAIA core. It SHOULD be omitted with PAIA auth requests to not confuse OAuth
clients.

The response header of a request error MUST include a `WWW-Authenticate` header field to
indicate the need of providing a proper access token. The field MAY include a short name of the
PAIA server with a "realm" parameter:

    WWW-Authenticate: Bearer
    WWW-Authenticate: Bearer realm="PAIA Core"

The following error responses are expected:[^errors]

[^errors]: The error list was compiled from the HTTP and OAuth 2.0 specifications,
[the Twitter API](https://dev.twitter.com/docs/error-codes-responses), [the
StackExchange API](https://api.stackexchange.com/docs/error-handling), and [the
GitHub API](http://developer.github.com/v3/#client-errors).

--------------------- ------ ------------------------------------------------------------------------
 error                 code   description
--------------------- ------ ------------------------------------------------------------------------
 not_found              404   Unknown request URL or unknown patron. Implementations SHOULD
                              first check authentication and prefer error `invalid_grant` or
                              `access_denied` to prevent leaking patron identifiers.

 not_implemented        501   Known but unsupported request URL (for instance a PAIA auth server
                              server may not implement `http://example.org/core/change`)

 invalid_request        405   Unexpected HTTP verb

 invalid_request        400   Malformed request (for instance error parsing JSON, unsupported
                              request content type, etc.)

 invalid_request        422   The request parameters could be parsed but they don’t match the
                              request method (for instance missing fields, invalid values, etc.)

 invalid_grant          401   The access token was missing, invalid, or expired

 insufficient_scope     403   The access token was accepted but it lacks permission for the request

 access_denied          403   Wrong or missing credentials to get an access token

 internal_error         500   An unexpected error occurred. This error corresponds to a bug in
                              the implementation of a PAIA auth/core server

 service_unavailable    503   The request couldn't be serviced because of a temporary failure

 bad_gateway            502   The request couldn't be serviced because of a backend failure
                              (for instance the library system’s database)

 gateway_timeout        504   The request couldn't be serviced because of a backend failure
--------------------- ------ ------------------------------------------------------------------------

For instance the following response could result from a request with malformed
URIs:

~~~~ {.json}
{
  "error": "invalid_request",
  "code": "422",
  "error_description": "malformed item identifier provided: must be an URI",
  "error_uri": "http://example.org/help/api"
}
~~~~

## Simple data types

The following data types are used to define request and response format:

string
  : A Unicode string. Strings MAY be empty.

nonnegative integer
  : An integer number larger than or equal to zero.

boolean
  : Either true or false. Note that omitted boolean values are *not* false by
    default but unknown!

date
  : A date value in `YYYY-MM-DD` format. A datetime value with time and timezone
    SHOULD be used instead, if possible.

datetime
  : A date value in `YYY-MM-DD` format, optionally followed by a time value. A
    time value consists of the letter `T` followed by `hh:mm:ss` format, and a
    timezone indicator (`Z` for UTC or `+hh:mm` or `-hh:mm`) where:

    * `YYYY` indicates a year (`0001` through `9999`)
    * `MM` indicates a month (`01` through `12`)
    * `DD` indicates a day (`01` through `31`)
    * `hh` indicates an hour (`00` through `23`)
    * `mm` indicates a minute (`00` through `59`)
    * `ss` indicates a second (`00` through `59`)

    Examples of valid datetime values include `2015-03-20` (a date),
    `2016-03-09T11:58:19+10:00`, and `2017-08-21T12:24:28-06:00`.

money
  : A monetary value with currency (format `[0-9]+\.[0-9][0-9] [A-Z][A-Z][A-Z]`),
    for instance `0.80 USD`.

email
  : A syntactically correct email address.

URI
  : A syntactically correct URI.

account state
  : A nonnegative integer representing the current state of a patron account.
    Possible values are:

    0. active
    1. inactive
    2. inactive because account expired
    3. inactive because of outstanding fees
    4. inactive because account expired and outstanding fees

    A PAIA server MAY define additional states which can be mapped to `1` by PAIA
    clients. In JSON account states MUST be encoded as numbers instead of strings.

service status
  : A nonnegative integer representing the current status in fulfillment of a
    service. In most cases the service is related to a document, so the service
	status is a relation between a particular document and a particular patron.
	Possible values are:

    0. no relation (this applies to most combinations of document and patron, and
       it can be expected if no other state is given)
    1. reserved (the document is not accessible for the patron yet, but it will be)
    2. ordered (the document is being made accessible for the patron)
    3. held (the document is on loan by the patron)
    4. provided (the document is ready to be used by the patron)
    5. rejected

    A PAIA server MUST NOT define any other service status. In JSON service status
    MUST be encoded as numbers instead of strings.

## Documents

[document]: #documents
[documents]: #documents
[document error]: #documents
[document errors]: #documents

A **document** is a key-value structure with the following fields:

 name         occ    data type             description
------------- ----- --------------------- ------------------------------------------------------------------
 status       1..1   service status        status (0, 1, 2, 3, 4, or 5)
 item         0..1   URI                   URI of a particular copy
 edition      0..1   URI                   URI of a the document (no particular copy)
 requested    0..1   URI                   URI that was originally requested
 about        0..1   string                textual description of the document
 label        0..1   string                call number, shelf mark or similar item label
 queue        0..1   nonnegative integer   number of waiting requests for the document or item
 renewals     0..1   nonnegative integer   number of times the document has been renewed
 reminder     0..1   nonnegative integer   number of times the patron has been reminded
 starttime    0..1   datetime              date and time when the status began
 endtime      0..1   datetime              date and time when the status will expire
 duedate      0..1   date                  date when the current status will expire (*deprecated*)
 cancancel    0..1   boolean               whether an ordered or provided document can be canceled
 canrenew     0..1   boolean               whether a document can be renewed
 error        0..1   string                textual document error, for instance if a request was rejected
 condition    0..1   [condition]           condition (only in responses to [request], [renew], or [cancel])
 storage      0..1   string                textual description of location of the document
 storageid    0..1   URI                   URI of location of the document
------------- ----- --------------------- ------------------------------------------------------------------

For each document at least an item URI or an edition URI MUST be given.
Together, item and edition URI MUST uniquely identify a document within
the set of documents related to a patron.

The fields `starttime` and `endtime` MUST be interpreted as following:

 status   starttime                        endtime
-------- -------------------------------- --------------------------------------------------------
 0        -                                -
 1        when the document was reserved   when the reserved document is expected to be available
 2        when the document was ordered    when the ordered document is expected to be available
 3        when the document was lend       when the loan period ends or ended (due)
 4        when the document is provided    when the provision will expire
 5        when the request was rejected    -

Note that timezone information is mandatory in these fields.  The field
`duedate` is deprecated. Clients SHOULD only use it as `endtime` if no
`endtime` was given.

If both `storage` and `storageid` are given, a PAIA server MUST return
identical values of `storage` for identical `id` and identical content
language.  PAIA clients MAY override the value of `storage` based on
`storageid` and a preferred language.

Unknown document URIs and failed attempts to request, renew, or cancel a
document MUST NOT result in a [request error](#request-errors). Instead they
are indicated by a document error with field `error`. Form and type of document
errors are not specified, so clients SHOULD use these messages for display
only.

If `condition` is given, a PAIA server MUST also include a document error for
the same document, for instance the error message "confirmation required". This
allows PAIA clients without support of [conditions and conformations] to treat
conditions as simple, unrecoverable document errors.

<div class="example">

An example of a document serialized in JSON is given below. In this case a
general document (`http://example.org/documents/9876543`) was requested an
mapped to a particular copy (`http://example.org/items/barcode1234567`) by the
PAIA server. The copy turned out to be lost, so the request was rejected
(status 5) at 2014-07-12, 14:07 UTC.

~~~~ {.json}
{
   "status":    5,
   "item":      "http://example.org/items/barcode1234567",
   "edition":   "http://example.org/documents/9876543",
   "requested": "http://example.org/documents/9876543",
   "starttime": "2014-07-12T14:07Z",
   "error":     "sorry, we found out that our copy is lost!"
}
~~~~

The following document could result from a [request] for an item given by an
unknown URI:

~~~~ {.json}
{
  "item": "http://example.org/some/uri",
  "error": "item URI not found"
}
~~~~

</div>

## Patron messages

[message]: #patron-messages

A **message** is a key-value structure with the following fields:

name    occ   data type description
------- ----- --------- ---------------------------------------------------
id      1..1  URI       unique message identifier as URI
about   1..1  string    message text without markup
date    1..1  datetime  message date
url     0..1  URL       URL of a human-readable page with more information

The unique message identifier MUST have the form

    {base}{uri_escaped_patron_identifier}/messages/{local_id}

where `base` is the PAIA core base URL and `local_id` is a local identifier,
for instance a random number.  The local identifier SHOULD only contain digits
and simple letters (a-z, A-Z).

Messages can be read and deleted with PAIA core methods [messages] and [delete messages].

## Conditions and confirmations

[condition]: #conditions-and-confirmations
[confirmation]: #conditions-and-confirmations
[conditions and conformations]: #conditions-and-confirmations

Conditions and confirmations can OPTIONALLY be used to require or to select
from additional options in [PAIA core] methods [request], [renew], and
[cancel]. For instance a PAIA server MAY allow to choose among multiple
delivery methods or it MAY require to explicitly agree to some terms of
services when a special document is requested.  A PAIA client without support
of conditions and confirmations will always be assigned to the default option
or it will experience a condition as [document error] if no default option is
available.

### Conditions {.unnumbered}

[condition types]: #conditions
[condition options]: #conditions

A **condition** is a key-value structure that maps condition types to condition
settings.

Conditions can be included in response field `condition` of a [document] if the
same document also includes a document error in field `error`. The error SHOULD
provide a short description of the condition, for instance "delivery type must
be selected" or "confirmation required".

A **condition type** is an URI that identifies the purpose of a condition. A
PAIA client MUST be able to handle arbitrary condition type URIs.  A PAIA
server SHOULD support at least the following two condition types:

* <http://purl.org/ontology/paia#StorageCondition>
  to select a document location
* <http://purl.org/ontology/paia#FeeCondition>
  to confirm or select a document service causing a fee

A **condition setting** is a key-value structure with the following keys:

 name      occ  data type           description
---------- ---- ------------------ ------------------------------------------
 option    1..n  condition option   list of condition options
 multiple  0..1  boolean            whether multiple options can be selected
 default   0..n  URI                set of default option identifiers
---------- ---- ------------------ ------------------------------------------

A missing field `multiple` MUST be treated equal to a `multiple` field with
value `false`. The field `default` MAY be an empty array --- this case MUST NOT
be confused with a missing field `default`. All URIs listed in field `default`
MUST also be included as field `id` of one condition option.

If multiple condition options are given, they SHOULD be ordered, for instance
by popularity.

A **condition option** is a key-value structure with the following keys:

 name      occ  data type  description
--------- ---- ---------- ---------------------------------------------
 id       1..1  URI        unique identifier of this option
 about    1..1  string     textual description or label of this option
 amount   0..1  money      fee implied by chosing this option
--------- ---- ---------- ---------------------------------------------

A condition setting MUST NOT contain multiple condition options with same `id`.
A PAIA server MUST return identical values of `about` for identical values of
`id` and identical content language.  PAIA clients MAY override the value of
`about` based on `id` and a preferred language.

Values of `amout` matching the regular expression `/^0+\.00/` MUST be treated
equal to no amount and vice versa.

A PAIA server SHOULD use the condition option id
<http://purl.org/ontology/dso#DocumentService> or other URIs from the [Document
Service Ontology] for condition options of type
<http://purl.org/ontology/paia#FeeCondition>. Id and amount of the selected
condition option SHOULD later occurr in response to request method
[fees](#fees).

<div class="example">
Most simple condition only contain a single condition type. In the following
example condition type <http://purl.org/ontology/paia#FeeCondition> is mapped
to a condition setting with one condition option. No default option is given,
so an explicit confirmation is required.

~~~json
{
  "http://purl.org/ontology/paia#FeeCondition": {
    "option": [
      {
        "id": "http://purl.org/ontology/dso#Loan",
        "about": "loan",
        "amount": "0.50 EUR"
      }
    ]
  }
}
~~~

The following condition contains two condition types. The first condition type
(<http://purl.org/ontology/paia#StorageCondition>) refers to a list of delivery
places. The first place is marked as default and the third place implies a fee.
The second condition type (<http://example.org/purpose>) lists two options
which can also be selected together. An empty set is given as default option.

~~~json
{
  "http://purl.org/ontology/paia#StorageCondition": {
    "option": [
      {
        "id": "http://example.org/locations/pickup-desk",
        "about": "pickup desk"
      },
      {
        "id": "http://example.org/locations/branch",
        "about": "branch office"
      },
      {
        "id": "http://example.org/services/home-delivery",
        "amount": "2.50 EUR",
        "about": "home delivery"
      }
    ],
    "default": [ "http://example.org/locations/pickup-desk" ]
  },
  "http://example.org/purpose": {
    "multiple": true,
    "option": [
      {
        "id": "http://example.org/purpose/research",
        "about": "document usage for research"
      },
      {
        "id": "http://example.org/purpose/leisure",
        "about": "document usage for leisure"
      }
    ],
    "default": [ ]
  }
}
~~~
</div>

### Confirmations {.unnumbered}

Confirmations can be sent as part of a [PAIA core] request of methods
[request], [renew], and [cancel] in field `confirm` of a document to choose
among condition options for selected condition types.

A **confirmation** is a key-value structure that maps [condition types] to
(possibly empty) sets of identifiers of selected [condition options].

<div class="example">
This confirmation confirms condition type
<http://purl.org/ontology/paia#FeeCondition> with condition option identified
by <http://purl.org/ontology/dso#DocumentService> and confirms another
condition type with two options from the example condition given above:

```json
{
  "http://purl.org/ontology/paia#FeeCondition": [
    "http://purl.org/ontology/dso#DocumentService"
  ],
  "http://example.org/purpose": [
    "http://example.org/purpose/research",
    "http://example.org/purpose/leisure"
  ]
}
```
</div>

<div class="note">
Valid confirmations can be empty, which is distinct from a missing
confirmation.  Confirmations can also contain empty lists of option
identifiers:

```json
{ }
{ "http://purl.org/ontology/paia#FeeCondition": [ ] }
```
</div>

### How conditions are met {.unnumbered}

A PAIA server MUST use the following algorithm or an equivalent mechanism to
check whether a given [condition] is met by a given [confirmation] or by a
missing `confirm` field. If a condition is not met, the server MUST return a
[document error] for the given document.

1. If no confirmation is given, a default confirmation is created by
   mapping all condition types to the default values of their condition
   settings.

2. All condition types in the conformation are removed, unless they
   have a correspondence in the condition.

3. All condition option identifiers in the conformation are removed,
   unless they also occur in the condition settings of the corresponding
   condition.

4. If the confirmation contains multiple condition option identifiers for
   a condition type that does not have a condition setting with field
   `multiple` set to `true`, all but the first identifier are removed.

5. The condition is not met, if there is a condition type in the condition
   without correspondence in the confirmation.

5. The condition is met if for each condition setting either field `default`
   is set to the empty array (`[ ]`) or the corresponding list of
   remaining option identifiers in the confirmation is not empty.

<div class="note">

To not select any default confirmation options, a PAIA client can send an empty
object (`{ }`).

Non applying condition types or options in a confirmation are ignored, so a
PAIA client can choose to *always* sent some custom default confirmation.

</div>

<div class="example">

The following condition contains the empty set as default value, so it is met
by *any* confirmation except a confirmation that does *not* include condition
type <http://example.org/purpose> (for instance `{ }`):

~~~json
{
  "http://example.org/purpose": {
    "multiple": true,
    "option": [
      { "id": "http://example.org/research", "about": "for research" },
      { "id": "http://example.org/leisure", "about": "for leisure" }
    ],
    "default": [ ]
  }
~~~

All other possible confirmations are reduced to one of this cases (the first
also used if no confirmation is given):

~~~
{ "http://example.org/purpose": [ ] }
{ "http://example.org/purpose": [ "http://example.org/research" ] }
{ "http://example.org/purpose": [ "http://example.org/leisure" ] }
{ "http://example.org/purpose": [ "http://example.org/research", "http://example.org/leisure" ] }
~~~

</div>


# PAIA core

Each API method of PAIA core is accessed at a URL that includes the
URI escaped patron identifier.

## patron

purpose
  : Get general information about a patron

HTTP verb and URL
  : GET https://example.org/core/**{uri_escaped_patron_identifier}**

scope
  : read_patron

response fields
  : name    occ  data type     description
    ------- ---- ------------- ---------------------------------------------
    name    1..1 string        full name of the patron
    email   0..1 email         email address of the patron
    address 0..1 string        freeform address of the patron
    expires 0..1 datetime      patron account expiry
    status  0..1 account state current state (0, 1, 2, or 3)
    type    0..n URI           list of custom URIs to identify patron types
    note    0..1 string        simple note to inform the patron
    ------- ---- ------------- ---------------------------------------------

PAIA server documentation SHOULD refer to a specialized API, such as LDAP, to
get more detailed patron information.

<div class="example">
~~~
GET /core/123 HTTP/1.1
Host: example.org
User-Agent: MyPAIAClient/1.0
Accept: application/json
Authorization: Bearer a0dedc54bbfae4b
~~~

~~~
HTTP/1.1 200 OK
X-PAIA-Version: 1.3.0
Content-Type: application/json; charset=utf-8
X-Accepted-OAuth-Scopes: read_patron
X-OAuth-Scopes: read_fees read_items read_patron write_items read_messages delete_messages
~~~

~~~{.json}
{
  "name": "Jane Q. Public",
  "email": "jane@example.org",
  "address": "Park Street 2, Springfield",
  "expires": "2015-05-18",
  "status": 0,
  "type": ["http://example.org/usertypes/default"]
}
~~~
</div>

## update patron

purpose
  : Update general information about a patron

HTTP verb and URL
  : PATCH https://example.org/core/**{uri_escaped_patron_identifier}**

scopes
  : update_patron / update_patron_name / update_patron_email / update_patron_address

request parameters
  : name      occ    data type  description
    --------- ------ --------- ------------------------------------
     name      0..1   string    new full name of the patron
     email     0..1   email     new email address of the patron
     address   0..1   string    new freeform address of the patron
    --------- ------ --------- ------------------------------------

response fields
  : Same as [patron] method on success, [error](#request-errors) otherwise.

This PAIA core method can be used to modify parts of the general patron
information:  Fields "name", "email", and "address" can be changed with scope
`update_patron` for all of these fields, or with the scopes
`update_patron_name`, `update_patron_email`, and/or `update_patron_address` for
each corresponding field.

This PAIA core method will be introduced with PAIA 1.4.0.  A PAIA server MAY
chose not not implement this method and return an [error response] with error
code `access_denied` (403), `invalid_request` (405), or `not_implemented` (501)
instead.

<div class="note">
Update of patron fields expires, status, and type via this method is not
supported.  To change a patron password see method [change] of PAIA auth.
</div>

<div class="example">
~~~
PATCH /core/123 HTTP/1.1
Host: example.org
User-Agent: MyPAIAClient/1.0
Accept: application/json
Content-Type: application/json
Authorization: Bearer 08568be488a2539
~~~

~~~{.json}
{
  "email": "janes-new-mail@example.com"
}
~~~

~~~
HTTP/1.1 200 OK
X-PAIA-Version: 1.3.0
Content-Type: application/json; charset=utf-8
X-Accepted-OAuth-Scopes: update_patron update_patron_email
X-OAuth-Scopes: read_patron update_patron
~~~

~~~{.json}
{
  "name": "Jane Q. Public",
  "email": "janes-new-mail@example.com",
  "address": "Park Street 2, Springfield",
  "expires": "2015-05-18",
  "status": 0,
  "type": ["http://example.org/usertypes/default"]
}
~~~
</div>

## items

purpose
  : Get a list of loans, reservations and other items related to a patron

HTTP verb and URL
  : GET https://example.org/core/**{uri_escaped_patron_identifier}**/items

scope
  : read_item

response fields
  :  name   occ    data type  description
    ------ ------ ---------- -----------------------------------------
     doc    0..n  [document]  list of documents (order is irrelevant)
    ------ ------ ---------- -----------------------------------------

In most cases, each document will refer to a particular copy (`doc.item`), but
users may also have requested (`doc.requested`) and/or reserved (`doc.edition`)
an edition.

<div class="example">
~~~
GET /core/123/items HTTP/1.1
Host: example.org
User-Agent: MyPAIAClient/1.0
Accept: application/json
Authorization: Bearer a0dedc54bbfae4b
~~~

~~~
HTTP/1.1 200 OK
Content-Type: application/json; charset=utf-8
X-PAIA-Version: 1.3.0
X-Accepted-OAuth-Scopes: read_patron
X-OAuth-Scopes: read_items read_patron
~~~

~~~{.json}
{
  "doc": [{
    "status": 3,
    "item": "http://bib.example.org/105359165",
    "edition": "http://bib.example.org/9782356",
    "about": "Maurice Sendak (1963): Where the wild things are",
    "label": "Y B SEN 101",
    "queue": 0,
    "renewals": 0,
    "reminder": 0,
    "starttime": "2014-05-08T12:37Z",
    "endtime": "2014-06-09",
    "cancancel": false,
  },{
    "status": 1,
    "item": "http://bib.example.org/8861930",
    "about": "Janet B. Pascal (2013): Who was Maurice Sendak?",
    "label": "BIO SED 03",
    "queue": 1,
    "starttime": "2014-05-12T18:07Z",
    "endtime": "2014-05-24",
    "cancancel": true,
    "storage": "pickup service desk",
    "storageid": "http://bib.example.org/library/desk/7",
  }]
}
~~~
</div>

## request

purpose
  : Request one or more items for reservation or delivery.

HTTP verb and URL
  : POST https://example.org/core/**{uri_escaped_patron_identifier}**/request

scope
  : write_item

request parameters
  :  name            occ   data type      description
    --------------- ------ -------------- ------------------------------------------
     doc             1..n  array           list of documents requested
     doc.item        0..1  URI             URI of a particular item
     doc.edition     0..1  URI             URI of a particular edition
     doc.confirm     0..1  [confirmation]  Confirmation
     doc.storageid   0..1  URI             Requested document location (deprecated)
    --------------- ------ -------------- ------------------------------------------

response fields
  :  name   occ    data type   description
    ------ ------ ----------- -----------------------------------------
     doc    1..n  [document]    list of documents (order is irrelevant)
    ------ ------ ----------- -----------------------------------------

The response SHOULD include the same documents as requested. A client MAY also
use the [items](#items) method to get the service status after request.

The field `doc.storageid` is deprecated and MUST be ignored if field
`doc.confirm` is given. Otherwise a PAIA core server SHOULD map the value of
field `doc.storageid` (e.g `http://example.org/a/location`) to a corresponding
[confirmation] in field `doc.confirm`:

```json
{
  "http://purl.org/ontology/paia#StorageCondition": [
    "http://example.org/a/location"
  ]
}
```

## renew

purpose
  : Renew one or more documents usually held by the patron. PAIA servers
    MAY also allow renewal of reserved, ordered, and provided documents.

HTTP verb and URL
  : POST https://example.org/core/**{uri_escaped_patron_identifier}**/renew

scope
  : write_item

request parameters
  : ------------- ------ -------------- -----------------------------
     doc           1..n  array           list of documents to renew
     doc.item      0..1  URI             URI of a particular item
     doc.edition   0..1  URI             URI of a particular edition
     doc.confirm   0..1  [confirmation]  Confirmation
    ------------- ------ -------------- -----------------------------

response fields
  :  name   occ   data type  description
    ------ ----- ---------- -----------------------------------------
     doc   1..n  [document]  list of documents (order is irrelevant)
    ----- ------ ---------- -----------------------------------------

The response SHOULD include the same documents as requested. A client MAY also
use the [items](#items) method to get the service status after renewal.


## cancel

purpose
  : Cancel requests for items.

HTTP verb and URL
  : POST https://example.org/core/**{uri_escaped_patron_identifier}**/cancel

scope
  : write_item

request parameters
  :  name          occ    data type
    ------------- ------ --------------- -----------------------------
     doc           1..n   array           list of documents to cancel
     doc.item      0..1   URI             URI of a particular item
     doc.edition   0..1   URI             URI of a particular edition
     doc.confirm   0..1   [confirmation]  Confirmation
    ------------- ------ --------------- -----------------------------

response fields
  :  name   occ   data type   description
    ------ ------ ---------- ----------------------------------------
     doc    1..n  [document]  list of documents (order is irrelevant)
    ------ ------ ---------- ----------------------------------------

## fees

purpose
  : Look up current fees of a patron.

HTTP verb and URL
  : GET https://example.org/core/**{uri_escaped_patron_identifier}**/fees

scope
  : read_fees

response fields
  :  name          occ    data type   description
    ------------- ------ ----------- ---------------------------------------------------------------
     amount        0..1   money       sum of all fees. May also be negative.
     fee           0..n   array       list of fees
     fee.amount    1..1   money       amount of a single fee
     fee.date      0..1   date        date when the fee was claimed
     fee.about     0..1   string      textual information about the fee
     fee.item      0..1   URI         item that caused the fee
     fee.edition   0..1   URI         edition that caused the fee
     fee.feetype   0..1   string      textual description of the type of service that caused the fee
     fee.feeid     0..1   URI         URI of the type of service that caused the fee
    ------------- ------ ----------- ---------------------------------------------------------------

A PAIA server MUST return identical values of `fee.feetype` for identical
`fee.feeid` and identical content language. PAIA clients MAY override the value
of `fee.feetype` based on `fee.feeid` and a preferred language.

If a fee was caused by a document (`fee.item` or `fee.edition` is set) then
`fee.feeid` SHOULD be taken as <http://purl.org/ontology/dso#DocumentService>
if not given and SHOULD be a class URI from the [Document Service Ontology]
otherwise. If the fee was confirmed with a [confirmation], the value of
`fee.feeid` SHOULD be the value of the confirmed condition option.

<div class="example">
~~~
GET /core/123/fees HTTP/1.1
Host: example.org
User-Agent: MyPAIAClient/1.0
Accept: application/json
Authorization: Bearer 90245facece931f
~~~

~~~
HTTP/1.1 200 OK
Content-Type: application/json; charset=utf-8
X-PAIA-Version: 1.3.0
X-Accepted-OAuth-Scopes: read_fees
X-OAuth-Scopes: read_patron read_items read_fees
~~~

~~~{.json}
{
  "amount": "18.00 EUR",
  "fee": [
    {
      "amount": "15.00 EUR",
      "date": "2016-05-13T00:00:00Z",
      "about": "annual fee"
    },
    {
      "amount": "2.50 EUR",
      "date": "2016-08-01T13:17:02Z",
      "item": "http://bib.example.org/105359165",
      "feeid": "http://example.org/services/home-delivery",
      "feetype": "home delivery"
    },
    {
      "amount": "0.50 EUR",
      "date": "2016-09-02T12:30:00Z",
      "item": "http://bib.example.org/105359165",
      "about": "late return",
      "feeid": "http://purl.org/ontology/dso#Loan",
      "feetype": "loan"
    }
  ]
}
~~~
</div>

<div class="note">
PAIA core server are not required to track lists of fees. A plain sum can be
returned as  single value like this:

~~~{.json}
{
  "amount": "3.00 EUR",
  "fee": [ { "amount": "3.00 EUR" } ]
}
~~~
</div>

## messages

[messages]: #messages

purpose
  : Look up individual patron messages

HTTP verb and URL
  : GET https://example.org/core/**{uri_escaped_patron_identifier}**/messages

scope
  : read_messages

response fields
  : name    occ  data type description
    ------- ---- --------- --------------------------------------
    message 0..n [message] list of messages (order is irrelevant)
    ------- ---- --------- --------------------------------------

A PAIA server MAY use field `note` of method [patron] as a simplified
alternative to individual patron messages. A PAIA server SHOULD NOT use
both ways to transport the same messages.

Single messages can also be retrieved by message URI:

GET https://example.org/core/**{uri_escaped_patron_identifier}**/messages/**{message_id}**

<div class="example">
~~~
GET /core/123/messages HTTP/1.1
Host: example.org
User-Agent: MyPAIAClient/1.0
Accept: application/json
Authorization: Bearer 90245facece931f
~~~

~~~
HTTP/1.1 200 OK
Content-Type: application/json; charset=utf-8
X-PAIA-Version: 1.3.0
X-Accepted-OAuth-Scopes: read_messages
X-OAuth-Scopes: read_patron read_items read_fees read_messages
~~~

~~~{.json}
{
  "message": [
    {
      "id": "http://example.org/core/123/messages/15",
      "about": "Your ordered item is ready for pickup at the reading room.",
      "date": "2018-06-04T12:24:28-06:00"
    },
    {
      "id": "http://example.org/core/123/messages/17",
      "about": "Your request is not possible, the ordered item is not available.",
      "date": "2018-07-02T09:45:03-04:21"
    },
    {
      "id": "http://example.org/core/123/messages/16",
      "about": "Thank you for your request. Your order will be processed.",
      "date": "2018-06-10T16:15:03-01:00"
    }
  ]
}
~~~
</div>

<div class="example">
~~~
GET /core/123/messages/15 HTTP/1.1
Host: example.org
User-Agent: MyPAIAClient/1.0
Accept: application/json
Authorization: Bearer 90245facece931f
~~~

~~~
HTTP/1.1 200 OK
Content-Type: application/json; charset=utf-8
X-PAIA-Version: 1.3.0
X-Accepted-OAuth-Scopes: read_messages
X-OAuth-Scopes: read_patron read_items read_fees read_messages
~~~

~~~{.json}
{
  "message": [
    {
      "id": "http://example.org/core/123/messages/15",
      "about": "Your ordered item is ready for pickup at the reading room.",
      "date": "2018-06-04T12:24:28-06:00"
    }
  ]
}
~~~
</div>

## delete messages

[delete messages]: #delete-messages

purpose
  : Delete individual patron messages

HTTP verb and URL
  : DELETE https://example.org/core/**{uri_escaped_patron_identifier}**/messages

scope
  : delete_messages
  
request parameters
  : name       occ    data type  description
    ---------- ------ ---------- ----------------------
    message    1..n   URI        list of message URIs
    ---------- ------ ---------- ----------------------
    
response fields
  : Same as [messages] method on success, [error](#request-errors) otherwise.

Single messages can also be deleted by message URI:

DELETE https://example.org/core/**{uri_escaped_patron_identifier}**/messages/**{message_id}**

<div class="example">
~~~
DELETE /core/123/messages HTTP/1.1
Host: example.org
User-Agent: MyPAIAClient/1.0
Accept: application/json
Authorization: Bearer 90245facece931f
~~~

~~~{.json}
{
  "message": [
    "http://example.org/core/123/messages/15"
  ]
}
~~~

~~~
HTTP/1.1 200 OK
Content-Type: application/json; charset=utf-8
X-PAIA-Version: 1.3.0
X-Accepted-OAuth-Scopes: delete_messages read_messages
X-OAuth-Scopes: read_patron read_items read_fees read_messages delete_messages
~~~

~~~{.json}
{
  "message": [
    {
      "id": "http://example.org/core/123/messages/17",
      "about": "Your request is not possible, the ordered item is not available.",
      "date": "2018-07-02T09:45:03-04:21"
    },
    {
      "id": "http://example.org/core/123/messages/16",
      "about": "Thank you for your request. Your order will be processed.",
      "date": "2018-06-10T16:15:03-01:00"
    }
  ]
}
~~~
</div>

<div class="example">
~~~
DELETE /core/123/messages/16 HTTP/1.1
Host: example.org
User-Agent: MyPAIAClient/1.0
Accept: application/json
Authorization: Bearer 90245facece931f
~~~

~~~
HTTP/1.1 200 OK
Content-Type: application/json; charset=utf-8
X-PAIA-Version: 1.3.0
X-Accepted-OAuth-Scopes: delete_messages read_messages
X-OAuth-Scopes: read_patron read_items read_fees read_messages delete_messages
~~~

~~~{.json}
{
  "message": [
    {
      "id": "http://example.org/core/123/messages/17",
      "about": "Your request is not possible, the ordered item is not available.",
      "date": "2018-07-02T09:45:03-04:21"
    }
  ]
}
~~~
</div>


# PAIA auth

**PAIA auth** defines three methods to get access tokens and patron identifiers
([login]), invalidate access tokens ([logout]), and change passwords
([change]). Access tokens and patron identifiers are required to access **[PAIA
core]** methods. There MAY be additional or alternative ways to distribute and
manage access tokens and patron identifiers.

A **PAIA auth** server acts as OAuth authorization server ([RFC 6749]) with
password credentials grant, as defined in [section
4.3](https://tools.ietf.org/html/rfc6749#section-4.3) of OAuth specification,
and/or client credentials grant, as defined in [section
4.4](https://tools.ietf.org/html/rfc6749#section-4.4) of the OAuth
specification.  The access tokens provided by the server are so called OAuth
2.0 bearer tokens ([RFC 6750]).

A **PAIA auth** server MUST protect against brute force attacks (e.g. using
rate-limitation or generating alerts). It is RECOMMENDED to further restrict
access to **PAIA auth** to specific clients, for instance by additional
authorization.

## login

The PAIA auth `login` method is the only PAIA method that does not require an
access token as part of the query. The URL of this method acts as OAuth Token
Endpoint to obtain access tokens. A PAIA auth server can implement passwort
credentials grant, client credentials grant, or both.

purpose
  : Get a patron identifier and access token to access patron information

URL
  : POST https://example.org/auth/**login**
    (a PAIA auth server MAY also support HTTP GET requests)

request header
  : The request header "Access" is required for client credentials grant
    with HTTP basic authentification as defined in [RFC 2617].

request parameters
  :  name          occ   data type
    ------------ ------ ----------- -------------------------------------------
     username     0..1   string      User name of a patron
     password     0..1   string      Password of a patron
     patron       0..1   string      Patron identifier
     grant_type   1..1   string      One of "password" and "client_credentials"
     scope        0..1   string      Space separated list of scopes
    ------------ ------ ----------- -------------------------------------------

    For passwort credentials grant

    * parameter "grant_type" MUST be set to "password"
    * parameters "username" and "password" are REQUIRED

    For client credentials grant

    * parameter "grant_type" MUST be set to "client_credentials"
    * parameters "username" and "password" SHOULD be ignored

The request parameter "patron" is only required if username or client
credentials do not uniquely refer to a patron identifier. The parameter SHOULD
be ignored otherwise. A username SHOULD uniquely identify a patron identifier.
A username MAY even be equal to a patron identifier, but this is NOT
RECOMMENDED.

If no `scope` parameter is given, and username or client credentials do not
imply a default scope, the scope SHOULD be set to the default value
`read_patron read_fees read_items write_items read_messages delete_messages`
for full access to all PAIA core methods (see [access tokens and scopes]).

The response format is a JSON structure as defined in section 5.1 (successful
response) and section 5.2 (error response) of OAuth 2.0. The PAIA auth server
MAY grant different scopes than requested for, for instance if the account of a
patron has expired, so the patron should not be allowed to request and renew
new documents.

response fields
  :  name            occ    data type              description
    --------------  ------ ---------------------  -------------------------------------------------
     patron          1..1   string                 Patron identifier
     access_token    1..1   string                 The access token issued by the PAIA auth server
     token_type      1..1   string                 Fixed value set to "Bearer" or "bearer"
     scope           1..1   string                 Space separated list of granted scopes
     expires_in      0..1   nonnegative integer    The lifetime in seconds of the access token
    --------------  ------ ---------------------  -------------------------------------------------

An access token SHOULD NOT be equal to the password of the same user.

<div class="example">
Successful login request with passwort grant:

~~~~
POST /auth/login HTTP/1.1
Host: example.org
User-Agent: MyPAIAClient/1.0
Accept: application/json
Content-Type: application/x-www-form-urlencoded
~~~~

~~~~
grant_type=password&username=alice02&password=jo-!97kdl%2B0tt
~~~~

~~~~
HTTP/1.1 200 OK
Content-Type: application/json; charset=utf-8
X-PAIA-Version: 1.3.0
X-OAuth-Scopes: read_patron read_fees read_items write_items read_messages delete_messages
Cache-Control: no-store
Pragma: no-cache
~~~~

~~~~ {.json}
{
  "access_token": "2YotnFZFEjr1zCsicMWpAA",
  "token_type": "Bearer",
  "expires_in": 3600,
  "patron": "8362432",
  "scope": "read_patron read_fees read_items write_items read_messages delete_messages"
}
~~~~

Login request with client credentials grant:

~~~~
POST /auth/login HTTP/1.1
Host: example.org
User-Agent: MyPAIAClient/1.0
Authorization: Basic b697689fa1adb419d86dbf8ffef9ce6d
Accept: application/json
Content-Type: application/x-www-form-urlencoded
~~~~

~~~~
grant_type=client_credentials&patron=8362432
~~~~

Response to a rejected login request:

~~~~
HTTP/1.1 403 Forbidden
Content-Type: application/json; charset=utf-8
X-PAIA-Version: 1.3.0
Cache-Control: no-store
Pragma: no-cache
WWW-Authenticate: Bearer realm="PAIA auth example"
~~~~

~~~~ {.json}
{
  "error": "access_denied",
  "error_description": "invalid patron or password"
}
~~~~
</div>

## logout

purpose
  : Invalidate an access token

URL
  : POST https://example.org/auth/**logout**
    (in addition a PAIA auth server MAY support HTTP GET requests)

request parameters
  :  name             occ    data type     description
    ---------------- ------ ----------- -----------------------
     patron           1..1   string      patron identifier
     token_type_hint  0..1   string      OAuth Token Type Hint
    ---------------- ------ ----------- -----------------------

response fields
  :  name     occ    data type     description
    -------- ------ ----------- -------------------
     patron   0..1   string      patron identifier
    -------- ------ ----------- -------------------

The logout method invalidates an access token, independent from the previous
lifetime of the token. On success, the server MUST invalidate at least the
access token that was used to access this method. The server MAY further
invalidate additional access tokens that were created for the same patron.

<div class="example">
~~~~
POST /auth/logout HTTP/1.1
Host: example.org
User-Agent: MyPAIAClient/1.0
Accept: application/json
Content-Type: application/x-www-form-urlencoded
Authorization: Bearer 2YotnFZFEjr1zCsicMWpAA

patron=8362432

HTTP/1.1 200 OK
Content-Type: application/json; charset=UTF-8
X-PAIA-Version: 1.3.0
~~~~

~~~~ {.json}
{
  "patron": "3110372827"
}
~~~~
</div>

## change

purpose
  : Change password of a patron

URL
  : POST https://example.org/auth/**change**

scope
  : change_password

request parameters
  :  name           occ    data type   description
    -------------- ------ ----------- ----------------------------
     patron         1..1   string      Patron identifier
     username       1..1   string      User name of the patron
     old_password   1..1   string      Password of the patron
     new_password   1..1   string      New password of the patron
    -------------- ------ ----------- ----------------------------

response fields
  :  name     occ    data type     description
    -------- ------ ----------- -------------------
     patron   1..1   string      patron identifier
    -------- ------ ----------- -------------------

The server MUST check

* the access token
* whether username and password match
* whether the user identified by username has scope `change_password`

A PAIA server MAY reject this method and return an [error response] with error
code `access_denied` (403) or error code `not_implemented` (501). On success,
the patron identifier is returned.

# Glossary

access token
  : A confidential random string that must be sent with each PAIA request
    for authentication.

document
  : A concrete or abstract document, such as a work, or an edition.

item
  : A concrete copy of a document, for instance a particular physical book.

PAIA auth server
  : HTTP endpoint that implements the PAIA auth specification, so
    all PAIA auth methods can be accessed at a common base URL.

PAIA core server
  : HTTP endpoint that implements the PAIA core specification, so
    all PAIA core methods can be accessed at a common base URL.

patron
  : An account of a library user

patron identifier
  : A Unicode string that identifies a library patron account.

# Security considerations

Security of OAuth 2.0 with bearer tokens relies on correct application of
HTTPS.  It is known that SSL certificate errors are often ignored just because
of laziness. It MUST be clear to all implementors that this breaks the
chain of trust and is as secure as sending access tokens in plain text.

To limit the risk of spoiled access tokens, PAIA servers SHOULD put limits on
the lifetime of access tokens and on the number of allowed requests per minute
among other security limitations.

It is also known that several library systems allow weak passwords. For this reason
PAIA auth servers MUST follow appropriate security measures, such as protecting
against brute force attacks and blocking accounts with weak passwords or with
passwords that have been sent unencrypted.

# Informative parts

This non-normative section contains additional examples and explanations to
illustrate the semantics of PAIA concepts and methods and usage.

## Transitions of service states

Six service status [data type](#simple-data-types) values are possible. One
document can have different status for different patrons and for different
times. The following table illustrates reasonable transitions of service status
with time for a fixed patron. For instance some document held by another patron
is first requested (0 → 1) with PAIA method [request](#request), made available
after return (1 → 4), picked up (4 → 3), renewed after some time with PAIA
method [renew](#renew) (3 → 3) and later returned (3 → 0).

  transition →      0              1: reserved     2: ordered    3: held   4: provided     5: rejected
 -------------- --------------- --------------- --------------- --------- --------------- ------------------------------------
  0              =               `request`       `request`       loan      `request`       `request`
  1: reserved    `cancel`        =               available       loan      available       patron inactive, document lost ...
  2: ordered     `cancel`        /               =               loan      available       patron inactive, document lost ...
  3: held        return          /               /               `renew`   /               /
  4: provided    not picked up   /               /               loan      =               patron inactive, ...
  5: rejected    time passed     patron active   patron active   /         patron active   =
 -------------- --------------- --------------- --------------- --------- --------------- ------------------------------------

Transitions marked with "/" may also be possible in special circumstances: for
instance a book ordered from the stacks (status 2) may turn out to be damaged,
so it is first repaired and reserved for the patron meanwhile (status 1).
Transitions for digital publications may also be different. Note that a PAIA
server does not need to implement all service status. A reasonable subset is
to only support 0, 1, 3, and 5.

## Digital documents

The handling of digital documents is subject to frequently asked questions. The
following rules of thumb may help:

* For most digital documents the concept of an item does not make sense and there
  is no URI of a particular copy. In this case the `document.edition` field should
  be used instead of `document.item`.
* For some digital documents there may be no distinction between status `provided`
  and status `held`.  The status `provided` should be preferred when the same
  document can be used by multiple patrons at the same time, and `held` should
  be used when the document can exclusively be used by the patron.

## PAIA core extensions to non-document services

A future version of PAIA may be extended to support services not related to
documents. For instance a patron may reserve a cabin or some other facility.
The following methods may be added to PAIA core for this purpose:

services
  : List non-document services related to a patron - similar to method [items].

servicetypes
  : Get a list of services that a patron may request, each with URI, name, and
    short description.

-----

# References

## Normative References

* Bradner, S. 1997. “RFC 2119: Key words for use in RFCs to Indicate Requirement Levels”.
  <http://tools.ietf.org/html/rfc2119>.

* Crockford, D. 2006. “RFC 6427: The application/json Media Type for JavaScript Object Notation (JSON)”.
  <http://tools.ietf.org/html/rfc4627>.

* Fielding, R. 1999. “RFC 2616: Hypertext Transfer Protocol”.
  <http://tools.ietf.org/html/rfc2616>.

* Franks, J. et al. 1999: “RFC 2617: HTTP Authentication: Basic and Digest Access Authentication”.
  <http://tools.ietf.org/html/rfc2617>.

* D. Hardt. 2012. “RFC 6749: The OAuth 2.0 Authorization Framework”.
  <http://tools.ietf.org/html/rfc6749>.

* Jones, M. and Hardt, D. 2012. “RFC 6750: The OAuth 2.0 Authorization Framework: Bearer Token Usage”.
  <http://tools.ietf.org/html/rfc6750>.

* van Kesteren, Anne. 2014. “Cross-Origin Resource Sharing”
  <http://www.w3.org/TR/cors/>

* Rescorla, E. 2000. “RFC 2818: HTTP over TLS.”
  <http://tools.ietf.org/html/rfc2818>.

[RFC 2119]: http://tools.ietf.org/html/rfc2119
[RFC 4627]: http://tools.ietf.org/html/rfc4627
[RFC 2616]: http://tools.ietf.org/html/rfc2616
[RFC 2617]: http://tools.ietf.org/html/rfc2617
[RFC 6749]: http://tools.ietf.org/html/rfc6749
[RFC 6750]: http://tools.ietf.org/html/rfc6750
[RFC 2818]: http://tools.ietf.org/html/rfc2818

## Informative References

* 3M. 2006. “3M Standard Interchange Protocol Version 2.00“.
  <http://mws9.3m.com/mws/mediawebserver.dyn?6666660Zjcf6lVs6EVs66S0LeCOrrrrQ->.

* ILS-DI. 2008. “DLF ILS Discovery Interface Task Group (ILS-DI) Technical Recommendation - revision 1.1“
  <http://old.diglib.org/architectures/ilsdi/>.

* Katz, D. 2013. “ILS Driver (VuFind 2.x)“.
  <http://vufind.org/wiki/vufind2:building_an_ils_driver>.

* NISO. 2010. “NISO Circulation Interchange Protocol (NCIP) - Z39.83-1-2008 Version 2.01“.
  <http://www.ncip.info/>.

* Voß, J. 2015. “PAIA Ontology“.
  <http://gbv.github.io/paia-rdf/>.

* Voß, J. 2014. “Document Service Ontology“
  <http://purl.org/ontology/dso>.

* “PAIA Wiki“.
  <https://github.com/gbv/paia/wiki>

[PAIA Ontology]: http://gbv.github.io/paia-rdf/
[Document Service Ontology]: http://gbv.github.io/dso/

## Revision history

This is version **{VERSION}** of PAIA specification, last modified at
{GIT_REVISION_DATE} with revision {GIT_REVISION_HASH}.

Version numbers follow [Semantic Versioning](http://semver.org/): each number
consists of three numbers, optionally followed by `+` and a suffix:

* The major version (first number) is increased if changes require
  a modification of PAIA clients
* The minor version (second number) is increased if changes require
  a modification of PAIA servers
* The patch version (third number) is increased for backwards compatible
  fixes or extensions, such as the introduction of new optional fields
* The optional suffix indicates informal changes in documentation

### Releases {.unnumbered}

Releases with functional changes are tagged with a version number and
included at <https://github.com/gbv/paia/releases> with release notes.

#### 1.3.3 (2017-03-29) {.unnumbered}

* add patron field `note`

#### 1.3.2 (2016-12-20) {.unnumbered}

* make response headers Content-Type, X-PAIA-Version, and 
  Access-Control-Allow-Headers (the latter only for OPTIONS requests) mandatory

#### 1.3.1 (2016-12-20) {.unnumbered}

* add PAIA core method to update patron
* extend PAIA auth login to optionally support OAuth client credentials grant
* extend PAIA auth logout method with token_type_hint and optional response fields

#### 1.3.0 (2015-11-06) {.unnumbered}

* introduce conditions and confirmations
* clarify uniqueness of storage/fee/condition id and textual description
* remove experimental reference to service ontology

#### 1.2.0 (2015-04-28) {.unnumbered}

* PAIA auth MUST support content type `application/x-www-form-urlencoded`
  to align with OAuth 2.0 (issue #50)

#### 1.1.0 (2015-04-21) {.unnumbered}

* add mandatory HTTP OPTIONS and optional HTTP HEAD requests
* extend CORS headers (`Access-Control-...`)
* fix name of `WWW-Authenticate` header
* remove request field `doc.storage` and deprecate field `doc.storageid`
* improve documentation

#### 1.0.8 (2015-04-16)  {.unnumbered}

* support content-negotiation for languages (issue #32)
* allow additional scopes not part of PAIA
* split PAIA ontology from PAIA specification

#### 1.0.7 (2015-04-14) {.unnumbered}

* add patron field `type`

#### 1.0.6 (2014-11-10) {.unnumbered}

* add patron field `address`

#### 1.0.5 (2014-07-16)  {.unnumbered}

* add CORS HTTP headers

#### 1.0.4 (2014-07-14) {.unnumbered}

* extend definition of datetime fields

#### 1.0.3 (2014-07-11) {.unnumbered}

* add document fields `starttime` and `endtime`

#### 1.0.1 (2013-11-20) {.unnumbered}

* add `User-Agent` header

### Full changelog {.unnumbered}

{GIT_CHANGES}
