# Monster
monster is a command-line cookie editor for OS X.

## Usage

*monster* operates on the current user's cookie jar. It supports three modes of operation - get, set, and eat (delete) - as follows:

> monster get url [key]

Get the value of the cookie(s) for url *url* with key *key*.  If *key* is not provided, all cookies set for *url* will be listed.

> monster set url key value [expiry]

Set a cookie for url *url* with key *key* and value *value*. Both *key* and *value* are required. If a cookie with key *key* exists, it will be modified; otherwise a new cookie will be created. *expiry* is an optional expiration date for the set cookie, in the form *<N> units notation*; *units* may be one of:
* s seconds
* m minutes
* h hours
* d days
* y years

> monster eat url key

Remove the the cookie for url *url* with key *key*. *key* is required; *monster* does not support deleting all cookies for a domain, mostly to avoid tragic mistakes.

*Note*: Both set and eat forms require that the user's cookie jar be writeable. Specifically, the write policy on the cookie jar must be *NSHTTPCookieAcceptPolicyAlways*.  *monster* will attempt to set the policy on the cookie jar if required, but depending on the user's browser security settings, this may fail.
