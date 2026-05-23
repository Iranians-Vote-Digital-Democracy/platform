package pg

import (
	"database/sql"
	"time"

	sq "github.com/Masterminds/squirrel"
	"github.com/jomhoor/sso-svc/internal/data"
	"github.com/pkg/errors"
)

const matrixPendingInvitesTable = "matrix_pending_invites"

type matrixPendingInvitesQ struct {
	db *sql.DB
}

// MatrixPendingInvites returns a query object for the matrix_pending_invites table.
func (d *DB) MatrixPendingInvites() data.MatrixPendingInvitesQ {
	return &matrixPendingInvitesQ{db: d.raw}
}

// Insert stores a new pending invite row and returns its auto-generated id.
// The caller should spawn the goroutine that does the actual Synapse API call
// only after this Insert succeeds.
func (q *matrixPendingInvitesQ) Insert(userID, roomID, action string) (int64, error) {
	query, args, err := sq.
		Insert(matrixPendingInvitesTable).
		Columns("user_id", "room_id", "action", "created_at").
		Values(userID, roomID, action, time.Now().UTC()).
		Suffix("RETURNING id").
		PlaceholderFormat(sq.Dollar).
		ToSql()
	if err != nil {
		return 0, errors.Wrap(err, "build insert matrix_pending_invite sql")
	}

	var id int64
	if err := q.db.QueryRow(query, args...).Scan(&id); err != nil {
		return 0, errors.Wrap(err, "exec insert matrix_pending_invite")
	}
	return id, nil
}

// Delete removes a row that was completed successfully by the goroutine.
func (q *matrixPendingInvitesQ) Delete(id int64) error {
	query, args, err := sq.
		Delete(matrixPendingInvitesTable).
		Where(sq.Eq{"id": id}).
		PlaceholderFormat(sq.Dollar).
		ToSql()
	if err != nil {
		return errors.Wrap(err, "build delete matrix_pending_invite sql")
	}
	if _, err := q.db.Exec(query, args...); err != nil {
		return errors.Wrap(err, "exec delete matrix_pending_invite")
	}
	return nil
}

// IncrementAttempts bumps the attempt counter and records the last error
// string so a future retry worker (or admin tooling) can inspect failures.
func (q *matrixPendingInvitesQ) IncrementAttempts(id int64, lastError string) error {
	query, args, err := sq.
		Update(matrixPendingInvitesTable).
		Set("attempts", sq.Expr("attempts + 1")).
		Set("last_error", nullIfEmpty(lastError)).
		Where(sq.Eq{"id": id}).
		PlaceholderFormat(sq.Dollar).
		ToSql()
	if err != nil {
		return errors.Wrap(err, "build update matrix_pending_invite sql")
	}
	if _, err := q.db.Exec(query, args...); err != nil {
		return errors.Wrap(err, "exec update matrix_pending_invite")
	}
	return nil
}
