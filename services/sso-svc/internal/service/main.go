package service

import (
	"net"
	"net/http"

	"github.com/jomhoor/sso-svc/internal/attestation"
	"github.com/jomhoor/sso-svc/internal/config"
	"github.com/jomhoor/sso-svc/internal/cookies"
	"github.com/jomhoor/sso-svc/internal/data/pg"
	"github.com/jomhoor/sso-svc/internal/deeplink"
	"github.com/jomhoor/sso-svc/internal/jwt"
	"github.com/jomhoor/sso-svc/internal/matrix"
	"github.com/jomhoor/sso-svc/internal/oidc"
	"github.com/jomhoor/sso-svc/internal/pairwise"
	"github.com/jomhoor/sso-svc/internal/zkp"
	"gitlab.com/distributed_lab/logan/v3"
)

type service struct {
	log         *logan.Entry
	listener    net.Listener
	jwt         *jwt.JWTIssuer
	oidc        *oidc.Config
	pairwise    *pairwise.Deriver
	attestation *attestation.Config
	cookies     *cookies.Cookies
	deeplink    *deeplink.Config
	db          *pg.DB
	zkp         *zkp.Verifier
	matrix      *matrix.Client
}

func (s *service) run() error {
	s.log.Info("sso-svc started")
	r := s.router()
	return http.Serve(s.listener, r)
}

func newService(cfg config.Config) *service {
	return &service{
		log:         cfg.Log(),
		listener:    cfg.Listener(),
		jwt:         cfg.JWT(),
		oidc:        cfg.OIDC(),
		pairwise:    cfg.Pairwise(),
		attestation: cfg.Attestation(),
		cookies:     cfg.Cookies(),
		deeplink:    cfg.Deeplink(),
		db:          cfg.DB(),
		zkp:         cfg.ZKP(),
		matrix:      cfg.Matrix(),
	}
}

func Run(cfg config.Config) {
	if err := newService(cfg).run(); err != nil {
		panic(err)
	}
}
