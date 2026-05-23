package pg

// nullIfEmpty maps the empty string to a typed nil so squirrel writes
// SQL NULL into nullable columns. We use this for OIDC-optional fields like
// oidc_nonce: an absent client `nonce` parameter is semantically "no nonce"
// (NULL), not "the empty-string nonce".
func nullIfEmpty(s string) any {
	if s == "" {
		return nil
	}
	return s
}
