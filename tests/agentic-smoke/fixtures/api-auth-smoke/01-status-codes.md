# API Auth Status Codes

Use `401 Unauthorized` when the caller has not authenticated or their token is missing or invalid.

Use `403 Forbidden` when the caller is authenticated but lacks permission for the resource.

Return `WWW-Authenticate` headers with `401` responses when the auth scheme requires the client to retry with credentials.
