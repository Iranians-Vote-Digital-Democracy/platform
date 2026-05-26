package config

import (
	"github.com/jomhoor/sso-svc/internal/admin"
	"github.com/jomhoor/sso-svc/internal/attestation"
	"github.com/jomhoor/sso-svc/internal/cookies"
	"github.com/jomhoor/sso-svc/internal/data/pg"
	"github.com/jomhoor/sso-svc/internal/deeplink"
	"github.com/jomhoor/sso-svc/internal/jwt"
	"github.com/jomhoor/sso-svc/internal/matrix"
	"github.com/jomhoor/sso-svc/internal/oidc"
	"github.com/jomhoor/sso-svc/internal/pairwise"
	"github.com/jomhoor/sso-svc/internal/zkp"
	"gitlab.com/distributed_lab/kit/comfig"
	"gitlab.com/distributed_lab/kit/kv"
)

type Config interface {
	comfig.Logger
	comfig.Listenerer
	jwt.Jwter
	oidc.Oidcer
	pairwise.Pairwiser
	attestation.Attestationer
	cookies.Cookier
	deeplink.Deeplinker
	pg.DBer
	zkp.Zkper
	matrix.Matrixer
	admin.Adminer
}

type config struct {
	comfig.Logger
	comfig.Listenerer
	jwt.Jwter
	oidc.Oidcer
	pairwise.Pairwiser
	attestation.Attestationer
	cookies.Cookier
	deeplink.Deeplinker
	pg.DBer
	zkp.Zkper
	matrix.Matrixer
	admin.Adminer
	getter kv.Getter
}

func New(getter kv.Getter) Config {
	return &config{
		getter:        getter,
		Listenerer:    comfig.NewListenerer(getter),
		Logger:        comfig.NewLogger(getter, comfig.LoggerOpts{}),
		Jwter:         jwt.NewJwter(getter),
		Oidcer:        oidc.NewOidcer(getter),
		Pairwiser:     pairwise.NewPairwiser(getter),
		Attestationer: attestation.NewAttestationer(getter),
		Cookier:       cookies.NewCookier(getter),
		Deeplinker:    deeplink.NewDeeplinker(getter),
		DBer:          pg.NewDBer(getter),
		Zkper:         zkp.NewZkper(getter),
		Matrixer:      matrix.NewMatrixer(getter),
		Adminer:       admin.NewAdminer(getter),
	}
}
