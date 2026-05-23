// Q1 ban middleware.
//
// Soft-deletes a wallet: any authenticated request whose pairwise subject
// resolves to a wallet with non-NULL `banned_at` is rejected with 403.
// Mounted after AuthMiddleware so we only pay the DB cost on already-valid
// tokens; mounted before the handler so the handler never sees a banned user.
package middleware

import (
	"net/http"

	"github.com/jomhoor/sso-svc/internal/data/pg"
	"github.com/jomhoor/sso-svc/internal/service/handlers"
	"gitlab.com/distributed_lab/ape"
	"gitlab.com/distributed_lab/ape/problems"
)

// BanMiddleware blocks requests from banned wallets.
//
// Resolution path:
//  1. claim.Subject  → pairwise_subjects row
//  2. ps.WalletID    → wallets.banned_at
//
// A missing pairwise row is treated as a hard 401 (the access token outlived
// its underlying identity). DB errors are 500.
func BanMiddleware() func(http.Handler) http.Handler {
	return func(next http.Handler) http.Handler {
		return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
			claim := handlers.Claim(r)
			if claim == nil {
				// Programmer error: BanMiddleware must run after AuthMiddleware.
				handlers.Log(r).Error("ban middleware: no claim in context (auth middleware missing?)")
				ape.RenderErr(w, problems.InternalError())
				return
			}

			db := handlers.DB(r)
			banned, err := isSubjectBanned(db, claim.Subject)
			if err != nil {
				handlers.Log(r).WithError(err).Error("ban middleware: resolve subject")
				ape.RenderErr(w, problems.InternalError())
				return
			}
			if banned {
				ape.RenderErr(w, problems.Forbidden())
				return
			}

			next.ServeHTTP(w, r)
		})
	}
}

// isSubjectBanned does pairwise → wallet → banned_at. Split out so handlers
// can call it directly if they ever need the same check inline.
func isSubjectBanned(db *pg.DB, subject string) (bool, error) {
	ps, err := db.PairwiseSubjects().GetBySubject(subject)
	if err != nil {
		return false, err
	}
	if ps == nil {
		// No pairwise row → can't be banned; let the handler decide what to
		// do with an orphaned subject. (validate/userinfo handle this fine.)
		return false, nil
	}
	return db.Wallets().IsBannedByID(ps.WalletID)
}
