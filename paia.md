% Patrons Account Information API (PAIA)
% Jakob Voß
% GIT_REVISION_DATE

# Introduction

The Patrons Account Information API (PAIA) is a HTTP based programming
interface to access library patron information, such as loans, reservations,
and fees.  Its primary goal is to provide patron access for discovery
interfaces and other third-party applications to integrated library system, as
easy as possible.


## Status of this document

This document is a first draft, based on a more elaborated version in German
that is being implemented. The specification has been created collaboratively
based on use cases and taking into account existing related standards and
products such as NISO Circulation Interchange Protocol (NCIP), \[X]SLNP,
DLF-ILS recommendations, and ViFind ILS drivers.

Updates and sources can be found at <http://github.com/gbv/paia>. The current
version of this document was last modified at GIT_REVISION_DATE with revision
GIT_REVISION_HASH.


## Conformance requirements

The key words "MUST", "MUST NOT", "REQUIRED", "SHALL", "SHALL NOT", "SHOULD",
"SHOULD NOT", "RECOMMENDED", "MAY", and "OPTIONAL" in this document are to be
interpreted as described in RFC 2119 [@RFC2119].

A PAIA server MUST implement PAIA core and it MAY implement PAIA auth.  If PAIA
auth is not implemented, another way SHOULD BE documented to distribute patron
identifiers and access tokens. A PAIA server MAY support only a subset of
methods but it MUST return a valid response on every method request.


# General 

PAIA consists of two independent parts:

* **[PAIA core](#paia-core)** defines six basic methods to look up,
  request and cancel loans and reservations, and to look up fees and general
  patron information.

* **[PAIA auth](#paia-auth)** defines three authentification methods (login,
  logout, and password update) to get access tokens, required by PAIA core.

Each method is accessed at an URL with a common base URL for PAIA core methods
and common base URL for PAIA auth methods. A server SHOULD NOT provide
additional methods at these base URLs and it MUST NOT propagate additional
methods at these base URLs as belonging to PAIA.

In the following, the base URL <https://example.org/core/> is used for PAIA
core and <https://example.org/auth/> for PAIA auth. 

Authentification in PAIA is based on OAuth 2.0 (@OAuth2) with bearer tokens
(@OAuth2Bearer) over HTTPS (@RFC2818).  For security reasons, PAIA methods MUST
be requested via HTTPS only. A PAIA client MUST NOT ignore SSL certificate
errors; otherwise access token (PAIA core) or even password (PAIA auth) are
compromised by the client.


## Request and response format

Each PAIA method is identified by a name which is appended to the PAIA
core/auth base URL to get the method’s full URL. In addition there is a set of
request parameters for each method. These parameters can be send as URL
parameters (HTTP GET) or as form fields with HTTP request content type set to
`application/x-www-form-urlencoded` (HTTP POST). In addition there is the
special request parameter `access_token` which MUST NOT be sent as URL
parameter (see section on [access tokens](#access-tokens) for details).

The HTTP response content type of a PAIA response is a JSON object (HTTP header
`Content-Type: application/json;charset=UTF-8`), optionally wrapped as JSONP
(HTTP header `Content-Type: application/javascript;charset=UTF-8`).


### Parameters and fields

Every request parameter and every response field is defined with

* the **name** of the parameter/field
* the **ocurrence** of the parameter/field being one of
    * `0..1` (optional, non repeatable)
    * `1..1` (mandatory, non repeatable)
    * `1..n` (mandatory, repeatbale)
    * `0..n` (optional, repeatable)
* the **[data type](#data-types)** of the parameter/field.

Simple parameter names and response fields consist of lowercase letters `a-z` only. For
repeatable request parameters, consecutive numbers (`1`, `2`, ...) must be appended to
the parameter name, unless the parameter is not repeated. For instance if `foo` is
a repeatable parameter, the following URL query strings are valid:

    ?foo=x
    ?foo1=x
    ?foo1=x&foo2=y

but the following URL query strings are invalid:

    ?foo1=x&foo3=y
    ?foo=x&foo=y

Repeatable response fields are encoded as JSON arrays, for instance:

    "foo": ["x","y"],

Hierarchical structures are possible with a dot (`.`) as separator. and with
objects in the JSON response. For instance the subfield/paramater `item` of the
first field/paramater `doc` is encoded as

    doc1.item=...

in a request or in a response as

    "doc" : [ { "item" : "..." } ]


## Access tokens

All PAIA methods, with [loginPatron](#loginpatron) from PAIA auth as only exception,
require an access token as special request parameter. The access token can be send
either as request parameter in the request body (HTTP POST) or as request header:

    curl -H "Authorization: Bearer vF9dft4qmT" https://example.org/core/getPatron


## Error response

...


## Special request parameters

* callback
* suppress_response_codes



## Data types

The following data types are supported:

string
  : A Unicode string. Strings MAY be empty.
nonnegative integer
  : An integer number larger than zero.
boolean
  : Either true or false (omitted boolean values are *not* false but unknown!).
date
  : A date value in `YYYY-MM-DD` format.
money
  : A monetary value with currency (format `[0-9]+\.[0-9][0-9] [A-Z][A-Z][A-Z]`),
    for instance `0.80 USD`.
email
  : syntactically correct email address.
URI
  : syntactically correct URI.
account state
  : A nonnegative integer representing the current state of a patron account. Possible
    values are:

    0. active
    1. inactive
    2. inactive because account expired
    3. inactive because of outstanding fees

    A PAIA server MAY define additional states which can be mapped to `1` by PAIA clients.
document state
  : A nonegative integer representing the current relation between a particular
    document and a particular patron. Possible values are:

    0. no relation (this applies to most combinations of document and patron, and
       it can be expected if no other state is given)
    1. reserved (the document is not accesible for the user yet, but it will be)
    2. ordered (the document is beeing made accesible for the user)
    3. held (the document is on loan by the patron)
    4. provided (the document is ready to be used by the patron)
    5. rejected

    A PAIA server MUST NOT define any other document states.


# PAIA core

## getPatron

purpose
  : Get general information about a patron
URL
  : https://example.org/core/**getPatron**
query parameters
  : -----------  ------ --------  -------------------
     username     1..1   String    patron identifier
    -----------  ------ --------  -------------------
response fields
  : ...

## getItems

purpose
  : Get a list of loans, reservations and other items related to a patron
URL
  : https://example.org/core/**getItems**
query parameters
  : -----------  ------ --------  -------------------
     username     1..1   String    patron identifier
    -----------  ------ --------  -------------------
response fields
  : ...


## renewItems

purpose
  : renew one or more documents held by the patron
URL
  : https://example.org/core/**renewItems**
query parameters
  : -----------  ------ --------  ----------------------------
     username     1..1   String    patron identifier
     doc          0..n             list of documents to renew
     doc.item     1..1   URI       URI of the particular item
    -----------  ------ --------  ----------------------------
response fields
  : ...


## requestItems

purpose
  : Request one or more items for reservation or delivery.
URL
  : https://example.org/core/**requestItems**
response fields
  : ...


## cancelItems

purpose
  : Cancel requests for items.
URL
  : https://example.org/core/**cancelItems**
response fields
  : ...


## getFunds

purpose
  : Look up current funds of a patron.
URL
  : https://example.org/core/**getFunds**
response fields
  : ...


# PAIA auth

**PAIA auth** defines three methods for authentification based on username and
password. These methods can be used to get access tokens and patron
identifiers, which are required to access **PAIA core** methods. There MAY be
additional or alternative ways to distribute and manage access tokens and
patron identifiers. 

There is no strict one-to-one relationship between username/password and patron
identifier/access token, but a username SHOULD uniquely identify a patron
identifier. A username MAY even be equal to a patron identifier, but this is
NOT RECOMMENDED.  An access token MUST NOT be equal to the password of the
same user.

A **PAIA auth** server acts as OAuth authorization server with password
credentials grant, as defined in section 4.3 of the OAuth 2.0 specification
[@OAuth2]. The access tokens provided by the server are so called OAuth 2.0 
Bearer Tokens (@OAuth2Bearer).

A **PAIA auth** server MUST protect against brute force attacks (e.g. using
rate-limitation or generating alerts). It is RECOMMENDED to further restrict
access to **PAIA auth** to specific clients, for instance by additional
authorization.


## loginPatron

The `loginPatron` method is the only PAIA method that does not require an
access token as part of the query.

purpose
  : Get a patron identifier and access token to access patron information
URL
  : https://example.org/auth/**loginPatron**
query parameters
  : ------------  ------ --------  ----------------------------
     username      1..1   string    User name of a patron 
     password      0..n             Password of a patron
     grant_type    1..1   string    Fixed value set to "password"
    ------------  ------ --------  -------------------------------

A `scope` parameter, as defined by OAuth 2.0 may be added in a future release
of this specification to provide access tokens with different access rights
(for instance read-only access). 

The response format is a JSON structure as defined in section 5.1 (successful
response) and section 5.2 (error response) of OAuth 2.0.

response fields
  : --------------  ------ ---------------------  -------------------------------------------------
     patron          1..1   string                 Patron identifier
     access_token    1..1   string                 The access token issued by the PAIA auth server
     token_type      1..1   string                 Fixed value set to "Bearer"
     expires_in      0..1   nonnegative integer    The lifetime in seconds of the access token
    --------------  ------ ---------------------  -------------------------------------------------

An example of a successful response:

    HTTPS/1.1 200 OK
    Content-Type: application/json;charset=UTF-8
    Cache-Control: no-store
    Pragma: no-cache

    {
      "access_token":"2YotnFZFEjr1zCsicMWpAA",
      "token_type":"Bearer",
      "expires_in":3600,
      "patron":"8362432"
    }


## logoutPatron

purpose
  : Invalidate an access token
URL
  : https://example.org/auth/**logoutPatron**
query parameters
  : --------  ------ --------  -------------------
     patron    1..1   string    Patron identifier
    --------  ------ --------  -------------------
response fields
  : --------  ------ --------  -------------------
     patron    1..1   string    Patron identifier
    --------  ------ --------  -------------------

The logout method invalidates an access token, independent from the previous
lifetime of the token. On success, the server MUST invalidate at least the
access token that was used to access this method. The server MAY further
invalidate additional access tokens that were created for the same patron.


## changeLogin

purpose
  : Change password of a patron.
URL
  : https://example.org/auth/**changeLogin**
query parameters
  : ---------- ------ --------  ----------------------------
     patron     1..1   string    Patron identifier
     username   1..1   string    User name of the patron 
     password   1..1   string    Password of the patron
     new        1..1   string    New password of the patron
    --------   ------ --------  ----------------------------

The server MUST check 

* the access token 
* whether username and password match
* whether the user identified by username is allowed to 
  change the given patrond’s password

A PAIA server MAY reject this method (TODO: document error response).


# Glossary

access token
  : A confidential random string that must be sent with each PAIA request
    for authentification.
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
patron identifier
  : A Unicode string that identifies a library patron account.

# References
