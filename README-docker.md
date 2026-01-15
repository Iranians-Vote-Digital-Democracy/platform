# Rarimo Backend Services - Local Development

This docker-compose setup runs all backend services required for the **inid-app**.

## Quick Start

```bash
# 1. Start PostgreSQL first
docker-compose up -d postgres

# 2. Wait for PostgreSQL to be ready
docker-compose logs -f postgres  # Wait for "database system is ready"

# 3. Start all services
docker-compose up -d

# 4. Check all services are running
docker-compose ps
```

## Services Overview

| Service | Port | Blockchain | Description |
|---------|------|------------|-------------|
| nginx (gateway) | 8000 | - | API gateway routing |
| decentralized-auth-svc | 8001 | ❌ | JWT authentication |
| registration-relayer | 8002 | ✅ WRITE | Identity registration |
| proof-verification-relayer | 8003 | ✅ WRITE | Vote transactions |
| geo-points-svc | 8004 | ✅ READ | Points & events |
| postgres | 5432 | - | Database |

## Required Configuration

### 1. Private Key Setup (REQUIRED for blockchain services)

Edit these config files and add your private key:
- `configs/registration-relayer.yaml` → `network.private_key`
- `configs/proof-verification-relayer.yaml` → `network.private_key` and `voting_v2.private_key`

⚠️ **IMPORTANT**: 
- Use a **dedicated relayer wallet**, not your main wallet
- The wallet needs **RMO tokens** on Rarimo L2 Testnet for gas
- Get testnet tokens from: https://faucet.testnet.rarimo.com

### 2. Contract Addresses

Default addresses are for **Rarimo L2 Testnet** (Chain ID: 7369).
For mainnet, update all contract addresses in the config files.

| Contract | Testnet Address |
|----------|-----------------|
| Registration | 0x511B5Ad9E911Ad5E87e3acb5862976F1398F9A68 |
| StateKeeper | 0x29516F57C90459c279CF1981D8BEb3b6C1d5B3dB |
| CertPoseidonSMT | 0x0473D9354069f1bD16A710b1A7d0494C61833Fff |
| RegistrationPoseidonSMT | 0xBdFA8630701e989E0436dAed6a8bFBa442D4FCC1 |
| ProposalState | 0x2Be5eF7434a14d08A2C8D8c886cBEB805ae7B671 |
| NoirIdVoting | 0x8ac45fc343Cd0D66cFC12bcdcD485DEF1DC1C11C |

## Testing the Setup

```bash
# Test auth service
curl http://localhost:8000/integrations/decentralized-auth-svc/v1/authorize/0x123/challenge

# Test points service (list event types)
curl http://localhost:8000/integrations/geo-points-svc/v1/public/event_types
```

## Connecting inid-app

Update your `.env.development` in inid-app:

```env
EXPO_PUBLIC_RELAYER_API_URL=http://localhost:8000
```

For physical device testing, replace `localhost` with your machine's IP address.

## Blockchain Choice: Rarimo L2

This system is designed **exclusively for Rarimo L2**. It cannot run on other EVM chains because:

1. **Custom Smart Contracts**: Uses Rarimo-specific contracts for identity, ZK proofs, and voting
2. **SMT (Sparse Merkle Tree)**: PoseidonSMT contracts are Rarimo-specific
3. **State Replication**: Uses Rarimo's cross-chain state replication system
4. **ZK Circuit Verification**: Verification keys are bound to Rarimo's deployed verifiers

### Rarimo L2 Networks

| Network | Chain ID | RPC URL | Explorer |
|---------|----------|---------|----------|
| Testnet | 7369 | https://l2.testnet.rarimo.com | https://scan.testnet.rarimo.com |
| Mainnet | 7368 | https://l2.rarimo.com | https://scan.rarimo.com |

## Service Dependencies

```
┌─────────────────┐
│    inid-app     │
│  (Mobile App)   │
└────────┬────────┘
         │ HTTP
         ▼
┌─────────────────┐
│     nginx       │ Port 8000
│   (Gateway)     │
└────────┬────────┘
         │
    ┌────┴────┬──────────┬──────────┐
    │         │          │          │
    ▼         ▼          ▼          ▼
┌───────┐ ┌───────┐ ┌─────────┐ ┌───────┐
│ auth  │ │ reg   │ │ proof   │ │ geo   │
│ svc   │ │relayer│ │ relayer │ │points │
└───────┘ └───┬───┘ └────┬────┘ └───┬───┘
              │          │          │
              │     ┌────┴────┐     │
              │     │         │     │
              ▼     ▼         ▼     ▼
         ┌─────────────┐  ┌─────────────┐
         │ Rarimo L2   │  │  PostgreSQL │
         │ Blockchain  │  │  Database   │
         └─────────────┘  └─────────────┘
```

## Troubleshooting

### Services won't start
```bash
docker-compose logs <service-name>
```

### Database connection issues
```bash
docker-compose exec postgres psql -U rarimo -c '\l'
```

### Blockchain transaction failures
- Check your wallet has RMO tokens
- Verify contract addresses match the network
- Check RPC endpoint is accessible

## Cleanup

```bash
docker-compose down -v  # Removes volumes (database data)
```
