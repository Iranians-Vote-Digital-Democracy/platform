package pg

import (
	"database/sql"
	"time"

	sq "github.com/Masterminds/squirrel"
	"github.com/jomhoor/sso-svc/internal/data"
	"github.com/pkg/errors"
)

const desktopSessionsTable = "desktop_sessions"

type desktopSessionsQ struct {
	db *sql.DB
}

func (d *DB) DesktopSessions() data.DesktopSessionsQ {
	return &desktopSessionsQ{db: d.raw}
}

func (q *desktopSessionsQ) Insert(s data.DesktopSession) error {
	query, args, err := sq.
		Insert(desktopSessionsTable).
		Columns("id", "client_id", "redirect_uri", "state", "expires_at").
		Values(s.ID, s.ClientID, s.RedirectURI, s.State, s.ExpiresAt).
		PlaceholderFormat(sq.Dollar).
		ToSql()
	if err != nil {
		return errors.Wrap(err, "build insert desktop session sql")
	}
	if _, err := q.db.Exec(query, args...); err != nil {
		return errors.Wrap(err, "exec insert desktop session")
	}
	return nil
}

// scan order shared by GetByID / BindCode / ConsumePoll.
const desktopSessionReturning = "id, client_id, redirect_uri, state, code, created_at, expires_at, consumed"

func scanDesktopSession(row interface{ Scan(...any) error }) (*data.DesktopSession, error) {
	var s data.DesktopSession
	if err := row.Scan(
		&s.ID, &s.ClientID, &s.RedirectURI, &s.State, &s.Code,
		&s.CreatedAt, &s.ExpiresAt, &s.Consumed,
	); err != nil {
		if errors.Is(err, sql.ErrNoRows) {
			return nil, nil
		}
		return nil, errors.Wrap(err, "scan desktop session")
	}
	return &s, nil
}

func (q *desktopSessionsQ) GetByID(id string) (*data.DesktopSession, error) {
	query, args, err := sq.
		Select(desktopSessionReturning).
		From(desktopSessionsTable).
		Where(sq.Eq{"id": id}).
		PlaceholderFormat(sq.Dollar).
		ToSql()
	if err != nil {
		return nil, errors.Wrap(err, "build select desktop session sql")
	}
	return scanDesktopSession(q.db.QueryRow(query, args...))
}

// BindCode is the wallet → desktop hand-off. Only the FIRST successful verify
// for a given session wins; subsequent attempts hit the `code IS NULL` guard
// and return nil (caller renders 409 Conflict).
func (q *desktopSessionsQ) BindCode(id, code string) (*data.DesktopSession, error) {
	query, args, err := sq.
		Update(desktopSessionsTable).
		Set("code", code).
		Where(sq.And{
			sq.Eq{"id": id},
			sq.Eq{"consumed": false},
			sq.Eq{"code": nil},
			sq.Gt{"expires_at": time.Now().UTC()},
		}).
		Suffix("RETURNING " + desktopSessionReturning).
		PlaceholderFormat(sq.Dollar).
		ToSql()
	if err != nil {
		return nil, errors.Wrap(err, "build bind desktop session sql")
	}
	return scanDesktopSession(q.db.QueryRow(query, args...))
}

// ConsumePoll is the desktop's read side. It is one-shot: once consumed=true,
// further polls return nil so a leaked sid cannot be used twice.
func (q *desktopSessionsQ) ConsumePoll(id string) (*data.DesktopSession, error) {
	query, args, err := sq.
		Update(desktopSessionsTable).
		Set("consumed", true).
		Where(sq.And{
			sq.Eq{"id": id},
			sq.Eq{"consumed": false},
			sq.NotEq{"code": nil},
			sq.Gt{"expires_at": time.Now().UTC()},
		}).
		Suffix("RETURNING " + desktopSessionReturning).
		PlaceholderFormat(sq.Dollar).
		ToSql()
	if err != nil {
		return nil, errors.Wrap(err, "build consume desktop session sql")
	}
	return scanDesktopSession(q.db.QueryRow(query, args...))
}
