# Seed `matrix-mas` client in sso-svc

Run **once** on the production host after deploying sso-svc and the Matrix stack.

The `matrix-mas` row binds MAS (the Matrix Authentication Service) to sso-svc as
an OIDC client. The `client_secret` value MUST match `upstream_oauth2.providers[id=jomhoor-sso].client_secret`
in `configs/mas/config.yaml` — sso-svc stores it bcrypt-hashed, MAS holds the plaintext.

## 1. Generate a strong client secret

```bash
SECRET="$(openssl rand -hex 32)"
echo "$SECRET"   # paste this into configs/mas/config.yaml
```

## 2. Bcrypt-hash the secret

Run a one-shot Go snippet (sso-svc’s own toolchain already has bcrypt):

```bash
docker exec -i sso-svc sh -c 'cat <<EOF | go run -' <<GO
package main
import (
    "fmt"; "os"
    "golang.org/x/crypto/bcrypt"
)
func main() {
    h, err := bcrypt.GenerateFromPassword([]byte(os.Args[1]), bcrypt.DefaultCost)
    if err != nil { panic(err) }
    fmt.Println(string(h))
}
GO
```

Or from your laptop (any Python with passlib):

```bash
python3 -c "import bcrypt, sys; print(bcrypt.hashpw(sys.argv[1].encode(), bcrypt.gensalt()).decode())" "$SECRET"
```

## 3. Insert the row

```bash
docker exec -i sso-postgres psql -U sso -d sso <<SQL
INSERT INTO sso_clients (id, client_secret, redirect_uris, zk_required, name, logo_url)
VALUES (
    'matrix-mas',
    '<paste bcrypt hash here>',
    ARRAY['https://mas.jomhoor.org/upstream/callback/01KS8ZC147EV0K4C2M2A35JMHG'],
    FALSE,  -- MAS login does not require ZK; tier is determined post-login (Phase 3)
    'Jomhoor Matrix',
    'https://jomhoor.org/images/logo.svg'
);
SQL
```

## 4. Verify

```bash
docker exec -it sso-postgres psql -U sso -d sso -c \
    "SELECT id, redirect_uris, zk_required, name FROM sso_clients WHERE id = 'matrix-mas';"
```

Then run the MAS upstream check:

```bash
docker exec -it mas mas-cli doctor
```

## Rotate the secret

```sql
UPDATE sso_clients SET client_secret = '<new bcrypt hash>' WHERE id = 'matrix-mas';
```

Then update `configs/mas/config.yaml` and restart MAS.
