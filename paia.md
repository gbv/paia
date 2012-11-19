% Patrons Account Information API (PAIA)
% Jakob Voß
% GIT_REVISION_DATE

# Introduction

The **Patrons Account Information API (PAIA)** is a HTTP based programming
interface to access library patron information, such as loans, reservations,
and fees.  Its primary goal is to provide patron access for discovery
interfaces and other third-party applications to integrated library system, as
easy as possible.


## Status of this document

The specification has been created collaboratively based on use cases and
taking into account existing related standards and products such as NISO
Circulation Interchange Protocol (NCIP), \[X]SLNP, DLF-ILS recommendations, and
VuFind ILS drivers among others.

Updates and sources can be found at <http://github.com/gbv/paia>. The current
version of this document was last modified at GIT_REVISION_DATE with revision
GIT_REVISION_HASH.


## Conformance requirements

The key words "MUST", "MUST NOT", "REQUIRED", "SHALL", "SHALL NOT", "SHOULD",
"SHOULD NOT", "RECOMMENDED", "MAY", and "OPTIONAL" in this document are to be
interpreted as described in RFC 2119.

A PAIA server MUST implement [PAIA core] and it MAY implement [PAIA auth].  If
PAIA auth is not implemented, another way SHOULD BE documented to distribute
patron identifiers and access tokens. A PAIA server MAY support only a subset
of methods but it MUST return a valid response or error response on every
method request, as defined in this document.


[PAIA core]: #paia-core
[PAIA auth]: #paia-auth
[patron]: #patron
[items]: #items
[renew]: #renew
[request]: #request
[cancel]: #cancel
[fees]: #fees
[login]: #login
[logout]: #logout
[change]: #change


# General 

PAIA consists of two independent parts:

* **[PAIA core]** defines six basic methods to look up loaned and reserved 
  [items], to [request] and [cancel] loans and reservations, and to look up 
  [fees] and general [patron] information.

* **[PAIA auth]** defines three authentification methods ([login], [logout], 
  and password [change]) to get access tokens, required by PAIA core.

Each method is accessed at an URL with a common base URL for PAIA core methods
and common base URL for PAIA auth methods. A server SHOULD NOT provide
additional methods at these base URLs and it MUST NOT propagate additional
methods at these base URLs as belonging to PAIA.

In the following, the base URL <https://example.org/core/> is used for PAIA
core and <https://example.org/auth/> for PAIA auth. 

Authentification in PAIA is based on **OAuth 2.0** (RFC 6749) with bearer
tokens (RFC 6750) over HTTPS (RFC 2818).  For security reasons, PAIA methods
MUST be requested via HTTPS only. A PAIA client MUST NOT ignore SSL certificate
errors; otherwise access token (PAIA core) or even password (PAIA auth) are
compromised by the client.


## Request and response format

Each PAIA method is identified by an URL and a HTTP verb (either HTTP GET or
HTTP POST). 

For POST methods a request body must be included in JSON format
(HTTP request header `Content-Type: application/json` or
`application/json;charset=UTF-8`). 

In addition there is the special request parameter `access_token` for an
[access token](#access-tokens-and-scopes), which can be sent either as HTTP
query parameter or in a HTTP request header. 

The HTTP response content type of a PAIA response is a JSON object (HTTP header
`Content-Type: application/json; charset=utf-8`), optionally wrapped as JSONP
(HTTP header `Content-Type: application/javascript; charset=utf-8`).


Every request parameter and every response field is defined with

* the **name** of the parameter/field
* the **ocurrence** (occ) of the parameter/field being one of
    * `0..1` (optional, non repeatable)
    * `1..1` (mandatory, non repeatable)
    * `1..n` (mandatory, repeatbale)
    * `0..n` (optional, repeatable)
* the **[data type](#data-types)** of the parameter/field.
* a short description

Simple parameter names and response fields consist of lowercase letters `a-z` only.

Repeatable response fields are encoded as JSON arrays, for instance:

~~~~ {.json}
{ "foo": ["x","y"] }
~~~~

Hierarchical JSON structures in this document are refereced with a dot (`.`) 
as separator. For instance the subfield/paramater `item` of the `doc` is referenced
as `doc.item` would refer to the following JSON structure:

~~~~ {.json}
{ "doc" : [ { "item" : "..." } ] }
~~~~


## Special request parameters

The following special request parameters can be added to any request as URL query parameters:

callback
  : A JavaScript callback method name to return JSONP instead of JSON. The
    callback SHOULD only contain alphanumeric characters and underscores; 
	any invalid characters MUST be stripped by a PAIA server. If callback
	is given, the response content type MUST be `application/javascript`.
suppress_response_codes
  : If this parameter is present, *all* responses MUST be returned with a 
    200 OK status code, even [error responses](#error-response).

 
## Access tokens and scopes

All PAIA methods, with [login](#login) from PAIA auth as only exception,
require an **access token** as special request parameter. The access token is a
so called bearer token as described in RFC 6750. The access token can be send
either as URL query parameter or in a HTTP header. For instance the following
requests both get information about patron `123` with access token
`vF9dft4qmT`:

    curl -H "Authorization: Bearer vF9dft4qmT" https://example.org/core/patron/123
    curl -H https://example.org/core/patron/123?access_token=vF9dft4qmT

An access token is valid for a limited set of actions, referred to as
**scope**.  The following scopes are possible:

read_patron
  : Get patron information by the [patron](#patron) method.
read_fees
  : Get fees of a patron by the [fees](#fees) method.
read_items
  : Get a patron’s item information by the [items](#items) method.
write_items
  : Request, renew, and cancel items by the [request](#request), 
    [renew](#renew), and [cancel](#cancel) methods.

For instance a particular token with scopes `read_patron` and `read_items` may
be used to for read-only access to information about a patron, including its
loans and requested items but not its fees.

A PAIA core server SHOULD send the following HTTP headers with every response:

X-OAuth-Scopes
  : A space-separated list of scopes, the current token has authorized
X-Accepted-OAuth-Scopes
  : A space-separated list of scopes, the current method checks for


## Error response

Two classes of errors must be distinguished:

Document errors
  : Unknown document URIs and failed attempts to request, renew, or cancel 
    a document _do not result_ in an error response. Instead they are
    indicated by the `doc.error` response field.

Request errors
  : Malformed requests, failed authentification, unsupported methods, and
    unexpected server errors such as backend downtime etc. MUST result in an 
	error response. An error response is returned with a HTTP status code 
	4xx (client error) or 5xx (server error) as defined in RFC 2616, unless
    the request parameter `suppress_response_codes` is given.

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
but it SHOULD be omitted with PAIA auth requests to not confuse OAuth clients.

The following error responses are expected:[^errors]

[^errors]: The error list was compiled from HTTP and OAuth 2.0 specifications,
[the Twitter API](https://dev.twitter.com/docs/error-codes-responses), [the
StackExchange API](https://api.stackexchange.com/docs/error-handling), and [the
GitHub API](http://developer.github.com/v3/#client-errors).

--------------------- ------ ------------------------------------------------------------------------
 error                 code   description
--------------------- ------ ------------------------------------------------------------------------
 not_found              404   Unknown request URL or unknown patron. Implementations SHOULD
                              first check authentification and prefer error `invalid_grant` or
                              `access_denied` to prevent leaking patron identifiers.

 not_implemented        501   Known but unspupported request URL (for instance a PAIA auth server
                              server may not implement `http://example.org/core/change`)

 invalid_request        405   Unexpected HTTP verb (all but GET, POST, HEAD)

 invalid_request        400   Malformed request (for instance error parsing JSON, unsupported
                              request content type, etc.)
 
 invalid_request        422   The request parameters could be parsed but they don’t match to the
                              request method (for instance missing fields, invalid values, etc.)

 invalid_grant          401   The access token was missing, invalid, or expired

 insufficient_scope     403   The access token was accepted but it lacks permission for the request

 internal_error         500   An unexpected error ocurred. This error corresponds to a bug in
                              the implementation of a PAIA auth/core server
 
 service_unavailable    503   The request couldn’t be serviced because of a temporary failure

 bad_gateway            502   The request couldn’t be serviced because of a backend failure
                              (for instance the library system’s database)
 
 gateway_timeout        504   The request couldn’t be serviced because of a backend failure
--------------------- ------ ------------------------------------------------------------------------

For instance the following response could result from a request with malformed URIs 

~~~~ {.json}
{
  "error": "invalid_request",
  "code": "422",
  "error_description": "malformed item identifier provided: must be an URI",
  "error_uri": "http://example.org/help/api"
}
~~~~


## Data types

The following data types are used to define request and response format:

string
  : A Unicode string. Strings MAY be empty.
nonnegative integer
  : An integer number larger than or equal to zero.
boolean
  : Either true or false. Note that omitted boolean values are *not* false by 
    default but unknown!
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

    A PAIA server MAY define additional states which can be mapped to `1` by PAIA 
    clients.  For convenience, account states in JSON can expressed both as numbers 
    (`0`) and as strings (`"0"`).
document status
  : A nonegative integer representing the current relation between a particular
    document and a particular patron. Possible values are:

    0. no relation (this applies to most combinations of document and patron, and
       it can be expected if no other state is given)
    1. reserved (the document is not accesible for the user yet, but it will be)
    2. ordered (the document is beeing made accesible for the user)
    3. held (the document is on loan by the patron)
    4. provided (the document is ready to be used by the patron)
    5. rejected

    A PAIA server MUST NOT define any other document states. For convenience, 
    document status in JSON can expressed both as numbers (`1`) and as strings (`"1"`).

document
  : A key-value structure with the following fields

     name        occ    data type             description
    ----------- ------ --------------------- ----------------------------------------------------------
     status      1..1   document status       status (0, 1, 2, 3, 4, or 5)
     item        0..1   URI                   URI of a particular copy
     edition     0..1   URI                   URI of a the document (no particular copy)
     requested   0..1   URI                   URI that was originally requested
     about       0..1   string                textual description of the document
     label       0..1   string                call number, shelf mark or similar item label
     queue       0..1   nonnegative integer   number of waiting requests for the document or item
     renewals    0..1   nonnegative integer   number of times the document has been renewed
     reminder    0..1   nonnegative integer   number of times the patron has been reminded
     duedate     0..1   date                  date of expiry of the document statue (most times loan)
     cancancel   0..1   boolean               whether an ordered or provided document can be canceled
     canrenew    0..1   boolean               whether a document can be renewed
     error       0..1   string                error message, for instance if a request was rejected
     storage     0..1   string                location of the document
     storageid   0..1   URI                   location URI
    ----------- ------ --------------------- ----------------------------------------------------------


    For each document at least an item URI or an edition URI MUST be given. The
    response fields `label`, `storage`, `storageid`, and `queue`
    correspond to properties in DAIA.

    An example of a document (with status 5=rejected) serialized in JSON is
    given below. In this case an arbitrary copy of a selected document was
    requested and mapped to a particular copy that turned out to be not accesible:

    ~~~~ {.json}
    {
       "status":    5,
       "item":      "http://example.org/items/barcode1234567",
       "edition":   "http://example.org/documents/9876543",
       "requested": "http://example.org/documents/9876543",
       "error":     "sorry, we found out that our copy is lost!"
    }
    ~~~~

# PAIA core

Each API method of PAIA core is accessed at an URL that includes the
URI-escaped patron identifier.

## patron

purpose
  : Get general information about a patron
HTTP verb and URL
  : GET https://example.org/core/**{uri_escaped_patron_identifier}**
scope
  : read_patron
response fields
  :  name      occ    data type       description
    --------- ------ --------------- ------------------------------
     name      1..1   string          full name of the patron
	 email     0..1   email           email address of the patron
	 expires   0..1   date            date of patron account expiry
	 status    0..1   account state   current state (0, 1, 2, or 3)
    --------- ------ --------------- -------------------------------
 
Additional field such as address may be added in a later revision.

**Example**

~~~
GET /core/patron/123 HTTP/1.1
Host: example.org
Accept: application/json
Authorization: Bearer a0dedc54bbfae4b
~~~

~~~
HTTP/1.1 200 OK
Content-Type: application/json; charset=utf-8
X-Accepted-OAuth-Scopes: read_patron
X-OAuth-Scopes: read_patron, read_fees, read_items, write_items
~~~

~~~{.json}
{
  "name": "Jane Q. Public", 
  "email": "jane@example.org",
  "expires": "2013-05-18",
  "status": 0
}
~~~

## items

purpose
  : Get a list of loans, reservations and other items related to a patron
HTTP verb and URL
  : GET https://example.org/core/**{uri_escaped_patron_identifier}**/items
scope
  : read_item
response fields
  :  name   occ    data type   description
    ------ ------ ----------- -----------------------------------------
     doc    0..n   document    list of documents (order is irrelevant)
    ------ ------ ----------- -----------------------------------------

In most cases, each document will have an item URI for a particular copy, but
users may also have requested an edition.


## renew

purpose
  : renew one or more documents held by the patron
HTTP verb and URL
  : POST https://example.org/core/**{uri_escaped_patron_identifier}**/renew
scope
  : write_item
request parameters
  : ------------- ------ -------- ------------------------------
     doc           1..n             list of documents to renew
     doc.item      0..1   URI       URI of a particular item
     doc.edition   0..1   URI       URI of a particular edition
    ------------- ------ --------  -----------------------------
response fields
  :  name   occ    data type   description
    ------ ------ ----------- -----------------------------------------
     doc   1..n   document     list of documents (order is irrelevant)
    ----- ------ ------------ -----------------------------------------


## request

purpose
  : Request one or more items for reservation or delivery.
HTTP verb and URL
  : POST https://example.org/core/**{uri_escaped_patron_identifier}**/request
scope
  : write_item
request parameters
  :  name            occ    data type   description
    --------------- ------ ----------- ------------------------------
     doc             1..n               list of documents to renew
     doc.item        0..1   URI         URI of a particular item
     doc.edition     0..1   URI         URI of a particular edition
     doc.storage     0..1   string      Requested pickup location
     doc.storageid   0..1   URI         Requested pickup location
    --------------- ------ ----------- ------------------------------
response fields
  :  name   occ    data type   description
    ------ ------ ----------- -----------------------------------------
     doc    1..n   document    list of documents (order is irrelevant)
    ------ ------ ----------- -----------------------------------------


## cancel

purpose
  : Cancel requests for items.
HTTP verb and URL
  : POST https://example.org/core/**{uri_escaped_patron_identifier}**/cancel
scope
  : write_item
request parameters
  :  name          occ    data type
    ------------- ------ ----------- -----------------------------
     doc           1..n               list of documents to renew
     doc.item      0..1   URI         URI of a particular item
     doc.edition   0..1   URI         URI of a particular edition
    ------------- ------ ----------- -----------------------------
response fields
  :  name   occ    data type   description
    ------ ------ ----------- -----------------------------------------
     doc    1..n   document    list of documents (order is irrelevant)
    ------ ------ ----------- -----------------------------------------


## fees

purpose
  : Look up current fees of a patron.
HTTP verb and URL
  : GET https://example.org/core/**{uri_escaped_patron_identifier}**/fees
scope
  : read_fees
response fields
  :  name          occ    data type   description
    ------------- ------ ----------- ----------------------------------------
     amount        0..1   money       Sum of all fees. May also be negative!
     fee           0..n               list of fees
	 fee.amount    1..1   money       amout of a single fee
	 fee.date      0..1   date        date when the fee was claimed
	 fee.about     0..1   string      textual information about the fee
	 fee.item      0..1   URI         item that caused the fee
	 fee.edition   0..1   URI         edition that caused the fee
    ------------- ------ ----------- ----------------------------------------


# PAIA auth

**PAIA auth** defines three methods for authentification based on username and
password. These methods can be used to get access tokens and patron
identifiers, which are required to access **[PAIA core]** methods. There MAY be
additional or alternative ways to distribute and manage access tokens and
patron identifiers. 

There is no strict one-to-one relationship between username/password and patron
identifier/access token, but a username SHOULD uniquely identify a patron
identifier. A username MAY even be equal to a patron identifier, but this is
NOT RECOMMENDED.  An access token MUST NOT be equal to the password of the
same user.

A **PAIA auth** server acts as OAuth authorization server (RFC 6749) with
password credentials grant, as defined in section 4.3 of the OAuth 2.0
specification.  The access tokens provided by the server are so called OAuth
2.0 bearer tokens (RFC 6750).

A **PAIA auth** server MUST protect against brute force attacks (e.g. using
rate-limitation or generating alerts). It is RECOMMENDED to further restrict
access to **PAIA auth** to specific clients, for instance by additional
authorization.


## login

The `login` method is the only PAIA method that does not require an access
token as part of the query.

purpose
  : Get a patron identifier and access token to access patron information
URL
  : https://example.org/auth/**login**
request parameters
  :  name          occ   data type
    ------------ ------ ----------- --------------------------------
     username     1..1   string      User name of a patron 
     password     1..1   string      Password of a patron
     grant_type   1..1   string      Fixed value set to "password"
     scope        0..1   string      Space separated list of scopes
    ------------ ------ ----------- --------------------------------

If no `scope` parameter is given, it is set to the default value `read_patron
read_fees read_items write_items` for full access to all PAIA core methods (see
[access tokens and scopes ](#access-tokens-and-scopes)).

The response format is a JSON structure as defined in section 5.1 (successful
response) and section 5.2 (error response) of OAuth 2.0. The PAIA auth server
may grant different scopes than requested for, for instance if the account of a
patron has expired, so the patron should not be allowed to request and renew
new documents.

response fields
  :  name            occ    data type              description
    --------------  ------ ---------------------  -------------------------------------------------
     patron          1..1   string                 Patron identifier
     access_token    1..1   string                 The access token issued by the PAIA auth server
     token_type      1..1   string                 Fixed value set to "Bearer"
     scope           1..1   string                 Space separated list of granted scopes
     expires_in      0..1   nonnegative integer    The lifetime in seconds of the access token
    --------------  ------ ---------------------  -------------------------------------------------

An example of a successful response (scopes omitted in this example):

    HTTP/1.1 200 OK
    Content-Type: application/json; charset=utf-8
    Cache-Control: no-store
    Pragma: no-cache

~~~~ {.json}
{
  "access_token": "2YotnFZFEjr1zCsicMWpAA",
  "token_type": "Bearer",
  "expires_in": 3600,
  "patron": "8362432",
  "scope": "read_patron read_fees read_items write_items"
}
~~~~

## logout

purpose
  : Invalidate an access token
URL
  : https://example.org/auth/**logout**
request parameters
  :  name     occ    data type     description
    -------- ------ ----------- -------------------
     patron   1..1   string      patron identifier
    -------- ------ ----------- -------------------
response fields
  :  name     occ    data type     description
    -------- ------ ----------- -------------------
     patron   1..1   string      patron identifier
    -------- ------ ----------- -------------------

The logout method invalidates an access token, independent from the previous
lifetime of the token. On success, the server MUST invalidate at least the
access token that was used to access this method. The server MAY further
invalidate additional access tokens that were created for the same patron.


## change

purpose
  : Change password of a patron
URL
  : https://example.org/auth/**change**
request parameters
  :  name       occ    data type   description
    ---------- ------ ----------- ----------------------------
     patron     1..1   string      Patron identifier
     username   1..1   string      User name of the patron 
     password   1..1   string      Password of the patron
     new        1..1   string      New password of the patron
    --------   ------ ----------- ----------------------------

The server MUST check 

* the access token 
* whether username and password match
* whether the user identified by username is allowed to 
  change the given patron’s password

A PAIA server MAY reject this method and return an [error
response](#error-response) with error code `access_denied` (403) or error code
`not_implemented` (501).


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

# Security Considerations

Security of OAuth 2.0 with bearer tokens relies on correct application of
HTTPS.  It is known that SSL certificate errors are often ignored just because
of laziness. It MUST be clear to all implementors that this spoils the whole
chain of trust and is as secure as sending access tokens in plain text.

To limit the risk of spoiled access tokens, PAIA servers SHOULD put limits on
the lifetime of access tokens and on the number of allowed requests per minute
among other security limitations. 

It is also known that several library systems allow weak passwords. For this reason
PAIA auth servers MUST follow approriate security measures, such as protecting 
against brute force attacks and blocking accounts with weak passwords or with
passwords that have been sent unencrypted.


# References

Bradner, S. 1997. “RFC 2119: Key words for use in RFCs to Indicate Requirement Levels.” http://tools.ietf.org/html/rfc2119.

Fielding, R. 1999. “RFC 2616: Hypertext Transfer Protocol.” http://tools.ietf.org/html/rfc2616.

D. Hardt. 2012. “RFC 6749: The OAuth 2.0 Authorization Framework.” http://tools.ietf.org/html/rfc6749.

Jones, M. and Hardt, D. 2012. “RFC 6750: The OAuth 2.0 Authorization Framework: Bearer Token Usage.” http://tools.ietf.org/html/rfc6750.

Rescorla, E. 2000. “RFC 2818: HTTP over TLS.” http://tools.ietf.org/html/rfc2818.
