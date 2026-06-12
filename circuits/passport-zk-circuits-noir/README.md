# Self-hosted Noir circuit artifacts

The nginx gateway serves this directory at:

```
<RELAYER_API_URL>/assets/circuits/passport-zk-circuits-noir/<circuit>.json
```

(local dev: `http://<YOUR_LOCAL_IP>:8000/assets/circuits/passport-zk-circuits-noir/...`)

These are circuits **not** published to Rarimo's public bucket. The wallet looks
them up by name in `jomhoor-wallet/modules/noir/index.ts`.

## Required artifacts

| Circuit | Profile | Source |
|---------|---------|--------|
| `registerIdentity_9_160_3_3_336_216_1_1080_3_256.json` | Iranian Passport Variant B — RSA-3072 / exponent 33259 / SHA-1 (`SIG_TYPE 9`) | `platform/services/passport-zk-circuits-noir/register_identity` |

## Building the Variant B (Type 9) circuit

The circuit logic already exists: `noir_dl_lib/src/not_passports_zk_circuits.nr`
handles `SIG_TYPE == 9` via `verify_rsa::<3072, 26, HASH_ALGO, 33259>`.

1. Generate `register_identity/src/main.nr` for the Type-9 parameters using the
   scripts under `register_identity/js/` (see its `Readme.md`).
2. Compile to ACIR bytecode with `nargo` (matching the Noir/bb version the
   wallet's native prover expects).
3. Export the bytecode JSON named exactly:
   `registerIdentity_9_160_3_3_336_216_1_1080_3_256.json`
4. Drop it in this directory.

After dropping the file:

```bash
cd platform
docker-compose up -d nginx           # or: docker-compose restart nginx
curl -I http://localhost:8000/assets/circuits/passport-zk-circuits-noir/registerIdentity_9_160_3_3_336_216_1_1080_3_256.json
```

A `200 OK` confirms the wallet can download it.
