// SPDX-License-Identifier: Apache-2.0
// Copyright 2022 Aztec
pragma solidity >=0.8.21;

uint256 constant N = 262144;
uint256 constant LOG_N = 18;
uint256 constant NUMBER_OF_PUBLIC_INPUTS = 5;
library HonkVerificationKey {
    function loadVerificationKey() internal pure returns (Honk.VerificationKey memory) {
        Honk.VerificationKey memory vk = Honk.VerificationKey({
            circuitSize: uint256(262144),
            logCircuitSize: uint256(18),
            publicInputsSize: uint256(5),
            ql: Honk.G1Point({ 
               x: uint256(0x1863c402c102d487c15dc1f3ace92d142abe58a12c1d2bfc17cae9fdc11d7234),
               y: uint256(0x13f19f6002fb8d8fa8c5818206553eeee46e187d653c8c98880bf523c338ea7a)
            }),
            qr: Honk.G1Point({ 
               x: uint256(0x1619e777046faa6d18815460f9c94ea7a2668e160f178a400297912a0899967e),
               y: uint256(0x0889cb3aa607297412ed93d4d032c7a3daef8547dadaa7d459c4d2e8ee24363c)
            }),
            qo: Honk.G1Point({ 
               x: uint256(0x1db1c0355c332398549e5ee47f438d4c6963421a5b7a19f0801a7a1b798fa750),
               y: uint256(0x1b69c9d66648dc8bc9e24131891da1ef091b4c11ea600b40a0fb781deec0b278)
            }),
            q4: Honk.G1Point({ 
               x: uint256(0x0d59ce26878cbdb2b28cde0cee0d53a4b34889f5e9fd21f1047c5172dca323a5),
               y: uint256(0x198bdaf485cc5910ad45915622ca0b0c0912c4aa859ed129a0cb5fe06f196b43)
            }),
            qm: Honk.G1Point({ 
               x: uint256(0x03e1d5644788ad23bdbf2e6436bc9b003784377780b38720440efff99279a944),
               y: uint256(0x139c1daa85a66e8e81f12ad35a0eb371a8fb955e18d8b31379e9e4d5c9668e03)
            }),
            qc: Honk.G1Point({ 
               x: uint256(0x061afa45d28ad88a843eb900a3b4fb8ec4c2bac691ece9071cb1cd464202fc34),
               y: uint256(0x2cbd329039693d2066a1757537ff4c955aab7960f1cbe743f5aeefc9fc987812)
            }),
            qArith: Honk.G1Point({ 
               x: uint256(0x0dea896c1486a49b3ab02e58a947e05a0651ef2127efd2d327168a19fdc1f1e8),
               y: uint256(0x1612b1931f2da66602c275c324de274428397b02be28d49894d3f4b4527fee8a)
            }),
            qDeltaRange: Honk.G1Point({ 
               x: uint256(0x24e3777e84ff523d7c400421b788212d0751b3927cb8e98f5e77c14a378b4d6d),
               y: uint256(0x213fb3a70a176f52d30c33d049f62a7030503186eae64c1f9a5aedc558dc4ff8)
            }),
            qElliptic: Honk.G1Point({ 
               x: uint256(0x2b4378889130fd062714760962765eb67718f7068a9bb55cf8da1386f67e0e1a),
               y: uint256(0x1880afa9b9254a6eacaf0b7e94f513ed32604e1b51e6eaac837c225611905f1d)
            }),
            qAux: Honk.G1Point({ 
               x: uint256(0x050bd97aaa5fc15a01930b27e0c0308424bf309745ccb1c2377ef85b55dff0b2),
               y: uint256(0x0c2fc37eea511ed6e36fddeb45384a1d8ff4a02063433d0697a552325387d33a)
            }),
            qLookup: Honk.G1Point({ 
               x: uint256(0x2214a957a8264fc4f4a67d6cc31872f1651ae8ddca8ed452ef7436e6b6331fe2),
               y: uint256(0x05834f5c74dd2d557c94e93d02afcac88519d76d420a5447ee13c11046f3c4bd)
            }),
            qPoseidon2External: Honk.G1Point({ 
               x: uint256(0x06a6d21725c58438a1ad74c8d37211e25d28b497820ea6480562ef2e880cfcb7),
               y: uint256(0x2a549ae2958016e6aa1cd8c7286ea499858ae8cee8c3230923a64b882708bd2c)
            }),
            qPoseidon2Internal: Honk.G1Point({ 
               x: uint256(0x1cca7b783c6c7c109bc466db9be6604e474bb5416dfbc6251cec9801b82e1742),
               y: uint256(0x1fd42206d3e740d4a5a3c643cf804d08b882e2960eb04321586ce206f3c88265)
            }),
            s1: Honk.G1Point({ 
               x: uint256(0x24e7eee9db2d2be6647aeb0e118bda4cd5d3455d55a387b53e3e97480ac9a951),
               y: uint256(0x10bf705657022be88ef4aa5e9775f7834a7d334a0801b149a005e51281b2b334)
            }),
            s2: Honk.G1Point({ 
               x: uint256(0x02ad1c63ad7cf3da1bbcb959b545685f80b4ab7f3e0f31f934a595ed3f6622ab),
               y: uint256(0x2f8d8c7ecbfdc79b660b33df62f77a039173bdded90154d70c3993316232694a)
            }),
            s3: Honk.G1Point({ 
               x: uint256(0x0ca3e8bd6c3048c3b835d7e8a7a6cab9db494b01fb3e21106036f8ac5c6c0225),
               y: uint256(0x0794616d320cc695864473036083baff03831a664484e37c6c4b0da038a61ead)
            }),
            s4: Honk.G1Point({ 
               x: uint256(0x22e1d5312774344de97e99d94e43413dd69d5b7b38f6a6ba1db3bff1ae0be550),
               y: uint256(0x0b0a3f0c5170ea12ab04ca0463eeb48fa85cd7971b7a95b80e00ab7ad6334743)
            }),
            t1: Honk.G1Point({ 
               x: uint256(0x1efe59446e3cf871e57a4c4a331d96cfd44ae16365c0ecd1fe7b0da9bf6d5195),
               y: uint256(0x1fb326fa0237824cf5106740b51a0e1d55e78025b8a0667977569b22b4a3326f)
            }),
            t2: Honk.G1Point({ 
               x: uint256(0x25e358c5b62e0b524ea709d340bc17bc3b5d40fcee7a21ec013fdf829af61ff8),
               y: uint256(0x1654009ba7919ee69dd35711ae5d0c75d29d6801b369feea818dd9617e80c215)
            }),
            t3: Honk.G1Point({ 
               x: uint256(0x1b8bbd9d2d972f3b26b90960861cd513a92392c8adbdabaf2aea725db6165557),
               y: uint256(0x04f9a59aa3c30120b6ee410f2ebe2db591076894dc32a216240d431d931c8617)
            }),
            t4: Honk.G1Point({ 
               x: uint256(0x300aab61734788c63920479722815f3b9b8406aed827471bd572139c67cca8fe),
               y: uint256(0x19950046e39a0d8d2c88e304696f155c3aaff5ce84f40232244a5574eada9bea)
            }),
            id1: Honk.G1Point({ 
               x: uint256(0x0b4c95c72a18cb1061e8604b60c27b579f549c509f6c9f43cec6a2e68da6a5e8),
               y: uint256(0x0bdbdc2452847e4e7161c209532741bfec0b125c9bdafed28490cefe77b88ece)
            }),
            id2: Honk.G1Point({ 
               x: uint256(0x0d340554aa810e492f27daf5a2775137ce5b60665e53918923a63e147bf37d97),
               y: uint256(0x211026c1ecc3926d8e84b4fdb2c4a9a3ecbab3bcc92f7f8db21695d23496640d)
            }),
            id3: Honk.G1Point({ 
               x: uint256(0x1e217bebbdc3e3e643a03909a1ebffd47396058a793506dbc9f652b4c1909541),
               y: uint256(0x05ce176028ea496aa036fe3a8c7a9145510a5d0896b5a356e493078df6cef5d0)
            }),
            id4: Honk.G1Point({ 
               x: uint256(0x0c66e7e183462a05c34a2ee355e545afd4daddc0e90847e65f23aea2eb6ac6ca),
               y: uint256(0x22a255d84ead8fa285c8ccd8abd42b509035d6fc572d7651c7601af2a2e459d5)
            }),
            lagrangeFirst: Honk.G1Point({ 
               x: uint256(0x0000000000000000000000000000000000000000000000000000000000000001),
               y: uint256(0x0000000000000000000000000000000000000000000000000000000000000002)
            }),
            lagrangeLast: Honk.G1Point({ 
               x: uint256(0x247e86c2c60ec440e5cf615b7056c14c867975ac85901d625e263b0a25d0e7ec),
               y: uint256(0x0d41d3755df07acb72a3a0d0ba0bf903b0c80ef3773baa3912114a1d55df78f4)
            })
        });
        return vk;
    }
}

pragma solidity ^0.8.27;

type Fr is uint256;

using { add as + } for Fr global;
using { sub as - } for Fr global;
using { mul as * } for Fr global;
using { exp as ^ } for Fr global;
using { notEqual as != } for Fr global;
using { equal as == } for Fr global;

uint256 constant MODULUS =
    21888242871839275222246405745257275088548364400416034343698204186575808495617; // Prime field order

Fr constant MINUS_ONE = Fr.wrap(MODULUS - 1);

// Instantiation
library FrLib
{
    function from(uint256 value) internal pure returns(Fr)
    {
        return Fr.wrap(value % MODULUS);
    }

    function fromBytes32(bytes32 value) internal pure returns(Fr)
    {
        return Fr.wrap(uint256(value) % MODULUS);
    }

    function toBytes32(Fr value) internal pure returns(bytes32)
    {
        return bytes32(Fr.unwrap(value));
    }

    function invert(Fr value) internal view returns(Fr)
    {
        uint256 v = Fr.unwrap(value);
        uint256 result;

        // Call the modexp precompile to invert in the field
        assembly
        {
            let free := mload(0x40)
            mstore(free, 0x20)
            mstore(add(free, 0x20), 0x20)
            mstore(add(free, 0x40), 0x20)
            mstore(add(free, 0x60), v)
            mstore(add(free, 0x80), sub(MODULUS, 2))
            mstore(add(free, 0xa0), MODULUS)
            let success := staticcall(gas(), 0x05, free, 0xc0, 0x00, 0x20)
            if iszero(success) {
                revert(0, 0)
            }
            result := mload(0x00)
        }

        return Fr.wrap(result);
    }

    function pow(Fr base, uint256 v) internal view returns(Fr)
    {
        uint256 b = Fr.unwrap(base);
        uint256 result;

        // Call the modexp precompile to invert in the field
        assembly
        {
            let free := mload(0x40)
            mstore(free, 0x20)
            mstore(add(free, 0x20), 0x20)
            mstore(add(free, 0x40), 0x20)
            mstore(add(free, 0x60), b)
            mstore(add(free, 0x80), v)
            mstore(add(free, 0xa0), MODULUS)
            let success := staticcall(gas(), 0x05, free, 0xc0, 0x00, 0x20)
            if iszero(success) {
                revert(0, 0)
            }
            result := mload(0x00)
        }

        return Fr.wrap(result);
    }

    function div(Fr numerator, Fr denominator) internal view returns(Fr)
    {
        return numerator * invert(denominator);
    }

    function sqr(Fr value) internal pure returns (Fr) {
        return value * value;
    }

    function unwrap(Fr value) internal pure returns (uint256) {
        return Fr.unwrap(value);
    }

    function neg(Fr value) internal pure returns (Fr) {
        return Fr.wrap(MODULUS - Fr.unwrap(value));
    }
}

// Free functions
function add(Fr a, Fr b) pure returns(Fr)
{
    return Fr.wrap(addmod(Fr.unwrap(a), Fr.unwrap(b), MODULUS));
}

function mul(Fr a, Fr b) pure returns(Fr)
{
    return Fr.wrap(mulmod(Fr.unwrap(a), Fr.unwrap(b), MODULUS));
}

function sub(Fr a, Fr b) pure returns(Fr)
{
    return Fr.wrap(addmod(Fr.unwrap(a), MODULUS - Fr.unwrap(b), MODULUS));
}

function exp(Fr base, Fr exponent) pure returns(Fr)
{
    if (Fr.unwrap(exponent) == 0) return Fr.wrap(1);

    for (uint256 i = 1; i < Fr.unwrap(exponent); i += i) {
        base = base * base;
    }
    return base;
}

function notEqual(Fr a, Fr b) pure returns(bool)
{
    return Fr.unwrap(a) != Fr.unwrap(b);
}

function equal(Fr a, Fr b) pure returns(bool)
{
    return Fr.unwrap(a) == Fr.unwrap(b);
}

uint256 constant CONST_PROOF_SIZE_LOG_N = 28;

uint256 constant NUMBER_OF_SUBRELATIONS = 26;
uint256 constant BATCHED_RELATION_PARTIAL_LENGTH = 8;
uint256 constant NUMBER_OF_ENTITIES = 44;
uint256 constant NUMBER_UNSHIFTED = 35;
uint256 constant NUMBER_TO_BE_SHIFTED = 9;

// Alphas are used as relation separators so there should be NUMBER_OF_SUBRELATIONS - 1
uint256 constant NUMBER_OF_ALPHAS = 25;

// Prime field order
uint256 constant Q = 21888242871839275222246405745257275088696311157297823662689037894645226208583; // EC group order. F_q
uint256 constant P = 21888242871839275222246405745257275088548364400416034343698204186575808495617; // Prime field order, F_r

// ENUM FOR WIRES
enum WIRE {
    Q_M,
    Q_C,
    Q_L,
    Q_R,
    Q_O,
    Q_4,
    Q_ARITH,
    Q_RANGE,
    Q_ELLIPTIC,
    Q_AUX,
    Q_LOOKUP,
    Q_POSEIDON2_EXTERNAL,
    Q_POSEIDON2_INTERNAL,
    SIGMA_1,
    SIGMA_2,
    SIGMA_3,
    SIGMA_4,
    ID_1,
    ID_2,
    ID_3,
    ID_4,
    TABLE_1,
    TABLE_2,
    TABLE_3,
    TABLE_4,
    LAGRANGE_FIRST,
    LAGRANGE_LAST,
    W_L,
    W_R,
    W_O,
    W_4,
    Z_PERM,
    LOOKUP_INVERSES,
    LOOKUP_READ_COUNTS,
    LOOKUP_READ_TAGS,
    TABLE_1_SHIFT,
    TABLE_2_SHIFT,
    TABLE_3_SHIFT,
    TABLE_4_SHIFT,
    W_L_SHIFT,
    W_R_SHIFT,
    W_O_SHIFT,
    W_4_SHIFT,
    Z_PERM_SHIFT
}

library Honk {
    struct G1Point {
        uint256 x;
        uint256 y;
    }

    struct G1ProofPoint {
        uint256 x_0;
        uint256 x_1;
        uint256 y_0;
        uint256 y_1;
    }

    struct VerificationKey {
        // Misc Params
        uint256 circuitSize;
        uint256 logCircuitSize;
        uint256 publicInputsSize;
        // Selectors
        G1Point qm;
        G1Point qc;
        G1Point ql;
        G1Point qr;
        G1Point qo;
        G1Point q4;
        G1Point qArith; // Arithmetic widget
        G1Point qDeltaRange; // Delta Range sort
        G1Point qAux; // Auxillary
        G1Point qElliptic; // Auxillary
        G1Point qLookup; // Lookup
        G1Point qPoseidon2External;
        G1Point qPoseidon2Internal;
        // Copy cnstraints
        G1Point s1;
        G1Point s2;
        G1Point s3;
        G1Point s4;
        // Copy identity
        G1Point id1;
        G1Point id2;
        G1Point id3;
        G1Point id4;
        // Precomputed lookup table
        G1Point t1;
        G1Point t2;
        G1Point t3;
        G1Point t4;
        // Fixed first and last
        G1Point lagrangeFirst;
        G1Point lagrangeLast;
    }

    struct Proof {
        uint256 circuitSize;
        uint256 publicInputsSize;
        uint256 publicInputsOffset;
        // Free wires
        Honk.G1ProofPoint w1;
        Honk.G1ProofPoint w2;
        Honk.G1ProofPoint w3;
        Honk.G1ProofPoint w4;
        // Lookup helpers - Permutations
        Honk.G1ProofPoint zPerm;
        // Lookup helpers - logup
        Honk.G1ProofPoint lookupReadCounts;
        Honk.G1ProofPoint lookupReadTags;
        Honk.G1ProofPoint lookupInverses;
        // Sumcheck
        Fr[BATCHED_RELATION_PARTIAL_LENGTH][CONST_PROOF_SIZE_LOG_N] sumcheckUnivariates;
        Fr[NUMBER_OF_ENTITIES] sumcheckEvaluations;
        // Shplemini
        Honk.G1ProofPoint[CONST_PROOF_SIZE_LOG_N - 1] geminiFoldComms;
        Fr[CONST_PROOF_SIZE_LOG_N] geminiAEvaluations;
        Honk.G1ProofPoint shplonkQ;
        Honk.G1ProofPoint kzgQuotient;
    }
}


// Transcript library to generate fiat shamir challenges
struct Transcript {
    Fr eta;
    Fr etaTwo;
    Fr etaThree;
    Fr beta;
    Fr gamma;
    Fr[NUMBER_OF_ALPHAS] alphas;
    Fr[CONST_PROOF_SIZE_LOG_N] gateChallenges;
    Fr[CONST_PROOF_SIZE_LOG_N] sumCheckUChallenges;
    // Shplemini
    Fr rho;
    Fr geminiR;
    Fr shplonkNu;
    Fr shplonkZ;
    // Derived
    Fr publicInputsDelta;
}

library TranscriptLib {
    function generateTranscript(Honk.Proof memory proof, bytes32[] calldata publicInputs, uint256 publicInputsSize)
        internal
        pure
        returns (Transcript memory t)
    {
        Fr previousChallenge;
        (t.eta, t.etaTwo, t.etaThree, previousChallenge) = generateEtaChallenge(proof, publicInputs, publicInputsSize);

        (t.beta, t.gamma, previousChallenge) = generateBetaAndGammaChallenges(previousChallenge, proof);

        (t.alphas, previousChallenge) = generateAlphaChallenges(previousChallenge, proof);

        (t.gateChallenges, previousChallenge) = generateGateChallenges(previousChallenge);

        (t.sumCheckUChallenges, previousChallenge) = generateSumcheckChallenges(proof, previousChallenge);

        (t.rho, previousChallenge) = generateRhoChallenge(proof, previousChallenge);

        (t.geminiR, previousChallenge) = generateGeminiRChallenge(proof, previousChallenge);

        (t.shplonkNu, previousChallenge) = generateShplonkNuChallenge(proof, previousChallenge);

        (t.shplonkZ, previousChallenge) = generateShplonkZChallenge(proof, previousChallenge);

        return t;
    }

    function splitChallenge(Fr challenge) internal pure returns (Fr first, Fr second) {
        uint256 challengeU256 = uint256(Fr.unwrap(challenge));
        uint256 lo = challengeU256 & 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF;
        uint256 hi = challengeU256 >> 128;
        first = FrLib.fromBytes32(bytes32(lo));
        second = FrLib.fromBytes32(bytes32(hi));
    }

    function generateEtaChallenge(Honk.Proof memory proof, bytes32[] calldata publicInputs, uint256 publicInputsSize)
        internal
        pure
        returns (Fr eta, Fr etaTwo, Fr etaThree, Fr previousChallenge)
    {
        bytes32[] memory round0 = new bytes32[](3 + publicInputsSize + 12);
        round0[0] = bytes32(proof.circuitSize);
        round0[1] = bytes32(proof.publicInputsSize);
        round0[2] = bytes32(proof.publicInputsOffset);
        for (uint256 i = 0; i < publicInputsSize; i++) {
            round0[3 + i] = bytes32(publicInputs[i]);
        }

        // Create the first challenge
        // Note: w4 is added to the challenge later on
        round0[3 + publicInputsSize] = bytes32(proof.w1.x_0);
        round0[3 + publicInputsSize + 1] = bytes32(proof.w1.x_1);
        round0[3 + publicInputsSize + 2] = bytes32(proof.w1.y_0);
        round0[3 + publicInputsSize + 3] = bytes32(proof.w1.y_1);
        round0[3 + publicInputsSize + 4] = bytes32(proof.w2.x_0);
        round0[3 + publicInputsSize + 5] = bytes32(proof.w2.x_1);
        round0[3 + publicInputsSize + 6] = bytes32(proof.w2.y_0);
        round0[3 + publicInputsSize + 7] = bytes32(proof.w2.y_1);
        round0[3 + publicInputsSize + 8] = bytes32(proof.w3.x_0);
        round0[3 + publicInputsSize + 9] = bytes32(proof.w3.x_1);
        round0[3 + publicInputsSize + 10] = bytes32(proof.w3.y_0);
        round0[3 + publicInputsSize + 11] = bytes32(proof.w3.y_1);

        previousChallenge = FrLib.fromBytes32(keccak256(abi.encodePacked(round0)));
        (eta, etaTwo) = splitChallenge(previousChallenge);
        previousChallenge = FrLib.fromBytes32(keccak256(abi.encodePacked(Fr.unwrap(previousChallenge))));
        Fr unused;
        (etaThree, unused) = splitChallenge(previousChallenge);
    }

    function generateBetaAndGammaChallenges(Fr previousChallenge, Honk.Proof memory proof)
        internal
        pure
        returns (Fr beta, Fr gamma, Fr nextPreviousChallenge)
    {
        bytes32[13] memory round1;
        round1[0] = FrLib.toBytes32(previousChallenge);
        round1[1] = bytes32(proof.lookupReadCounts.x_0);
        round1[2] = bytes32(proof.lookupReadCounts.x_1);
        round1[3] = bytes32(proof.lookupReadCounts.y_0);
        round1[4] = bytes32(proof.lookupReadCounts.y_1);
        round1[5] = bytes32(proof.lookupReadTags.x_0);
        round1[6] = bytes32(proof.lookupReadTags.x_1);
        round1[7] = bytes32(proof.lookupReadTags.y_0);
        round1[8] = bytes32(proof.lookupReadTags.y_1);
        round1[9] = bytes32(proof.w4.x_0);
        round1[10] = bytes32(proof.w4.x_1);
        round1[11] = bytes32(proof.w4.y_0);
        round1[12] = bytes32(proof.w4.y_1);

        nextPreviousChallenge = FrLib.fromBytes32(keccak256(abi.encodePacked(round1)));
        (beta, gamma) = splitChallenge(nextPreviousChallenge);
    }

    // Alpha challenges non-linearise the gate contributions
    function generateAlphaChallenges(Fr previousChallenge, Honk.Proof memory proof)
        internal
        pure
        returns (Fr[NUMBER_OF_ALPHAS] memory alphas, Fr nextPreviousChallenge)
    {
        // Generate the original sumcheck alpha 0 by hashing zPerm and zLookup
        uint256[9] memory alpha0;
        alpha0[0] = Fr.unwrap(previousChallenge);
        alpha0[1] = proof.lookupInverses.x_0;
        alpha0[2] = proof.lookupInverses.x_1;
        alpha0[3] = proof.lookupInverses.y_0;
        alpha0[4] = proof.lookupInverses.y_1;
        alpha0[5] = proof.zPerm.x_0;
        alpha0[6] = proof.zPerm.x_1;
        alpha0[7] = proof.zPerm.y_0;
        alpha0[8] = proof.zPerm.y_1;

        nextPreviousChallenge = FrLib.fromBytes32(keccak256(abi.encodePacked(alpha0)));
        (alphas[0], alphas[1]) = splitChallenge(nextPreviousChallenge);

        for (uint256 i = 1; i < NUMBER_OF_ALPHAS / 2; i++) {
            nextPreviousChallenge = FrLib.fromBytes32(keccak256(abi.encodePacked(Fr.unwrap(nextPreviousChallenge))));
            (alphas[2 * i], alphas[2 * i + 1]) = splitChallenge(nextPreviousChallenge);
        }
        if (((NUMBER_OF_ALPHAS & 1) == 1) && (NUMBER_OF_ALPHAS > 2)) {
            nextPreviousChallenge = FrLib.fromBytes32(keccak256(abi.encodePacked(Fr.unwrap(nextPreviousChallenge))));
            Fr unused;
            (alphas[NUMBER_OF_ALPHAS - 1], unused) = splitChallenge(nextPreviousChallenge);
        }
    }

    function generateGateChallenges(Fr previousChallenge)
        internal
        pure
        returns (Fr[CONST_PROOF_SIZE_LOG_N] memory gateChallenges, Fr nextPreviousChallenge)
    {
        for (uint256 i = 0; i < CONST_PROOF_SIZE_LOG_N; i++) {
            previousChallenge = FrLib.fromBytes32(keccak256(abi.encodePacked(Fr.unwrap(previousChallenge))));
            Fr unused;
            (gateChallenges[i], unused) = splitChallenge(previousChallenge);
        }
        nextPreviousChallenge = previousChallenge;
    }

    function generateSumcheckChallenges(Honk.Proof memory proof, Fr prevChallenge)
        internal
        pure
        returns (Fr[CONST_PROOF_SIZE_LOG_N] memory sumcheckChallenges, Fr nextPreviousChallenge)
    {
        for (uint256 i = 0; i < CONST_PROOF_SIZE_LOG_N; i++) {
            Fr[BATCHED_RELATION_PARTIAL_LENGTH + 1] memory univariateChal;
            univariateChal[0] = prevChallenge;

            for (uint256 j = 0; j < BATCHED_RELATION_PARTIAL_LENGTH; j++) {
                univariateChal[j + 1] = proof.sumcheckUnivariates[i][j];
            }
            prevChallenge = FrLib.fromBytes32(keccak256(abi.encodePacked(univariateChal)));
            Fr unused;
            (sumcheckChallenges[i], unused) = splitChallenge(prevChallenge);
        }
        nextPreviousChallenge = prevChallenge;
    }

    function generateRhoChallenge(Honk.Proof memory proof, Fr prevChallenge)
        internal
        pure
        returns (Fr rho, Fr nextPreviousChallenge)
    {
        Fr[NUMBER_OF_ENTITIES + 1] memory rhoChallengeElements;
        rhoChallengeElements[0] = prevChallenge;

        for (uint256 i = 0; i < NUMBER_OF_ENTITIES; i++) {
            rhoChallengeElements[i + 1] = proof.sumcheckEvaluations[i];
        }

        nextPreviousChallenge = FrLib.fromBytes32(keccak256(abi.encodePacked(rhoChallengeElements)));
        Fr unused;
        (rho, unused) = splitChallenge(nextPreviousChallenge);
    }

    function generateGeminiRChallenge(Honk.Proof memory proof, Fr prevChallenge)
        internal
        pure
        returns (Fr geminiR, Fr nextPreviousChallenge)
    {
        uint256[(CONST_PROOF_SIZE_LOG_N - 1) * 4 + 1] memory gR;
        gR[0] = Fr.unwrap(prevChallenge);

        for (uint256 i = 0; i < CONST_PROOF_SIZE_LOG_N - 1; i++) {
            gR[1 + i * 4] = proof.geminiFoldComms[i].x_0;
            gR[2 + i * 4] = proof.geminiFoldComms[i].x_1;
            gR[3 + i * 4] = proof.geminiFoldComms[i].y_0;
            gR[4 + i * 4] = proof.geminiFoldComms[i].y_1;
        }

        nextPreviousChallenge = FrLib.fromBytes32(keccak256(abi.encodePacked(gR)));
        Fr unused;
        (geminiR, unused) = splitChallenge(nextPreviousChallenge);
    }

    function generateShplonkNuChallenge(Honk.Proof memory proof, Fr prevChallenge)
        internal
        pure
        returns (Fr shplonkNu, Fr nextPreviousChallenge)
    {
        uint256[(CONST_PROOF_SIZE_LOG_N) + 1] memory shplonkNuChallengeElements;
        shplonkNuChallengeElements[0] = Fr.unwrap(prevChallenge);

        for (uint256 i = 0; i < CONST_PROOF_SIZE_LOG_N; i++) {
            shplonkNuChallengeElements[i + 1] = Fr.unwrap(proof.geminiAEvaluations[i]);
        }

        nextPreviousChallenge = FrLib.fromBytes32(keccak256(abi.encodePacked(shplonkNuChallengeElements)));
        Fr unused;
        (shplonkNu, unused) = splitChallenge(nextPreviousChallenge);
    }

    function generateShplonkZChallenge(Honk.Proof memory proof, Fr prevChallenge)
        internal
        pure
        returns (Fr shplonkZ, Fr nextPreviousChallenge)
    {
        uint256[5] memory shplonkZChallengeElements;
        shplonkZChallengeElements[0] = Fr.unwrap(prevChallenge);

        shplonkZChallengeElements[1] = proof.shplonkQ.x_0;
        shplonkZChallengeElements[2] = proof.shplonkQ.x_1;
        shplonkZChallengeElements[3] = proof.shplonkQ.y_0;
        shplonkZChallengeElements[4] = proof.shplonkQ.y_1;

        nextPreviousChallenge = FrLib.fromBytes32(keccak256(abi.encodePacked(shplonkZChallengeElements)));
        Fr unused;
        (shplonkZ, unused) = splitChallenge(nextPreviousChallenge);
    }

    function loadProof(bytes calldata proof) internal pure returns (Honk.Proof memory) {
        Honk.Proof memory p;

        // Metadata
        p.circuitSize = uint256(bytes32(proof[0x00:0x20]));
        p.publicInputsSize = uint256(bytes32(proof[0x20:0x40]));
        p.publicInputsOffset = uint256(bytes32(proof[0x40:0x60]));

        // Commitments
        p.w1 = Honk.G1ProofPoint({
            x_0: uint256(bytes32(proof[0x60:0x80])),
            x_1: uint256(bytes32(proof[0x80:0xa0])),
            y_0: uint256(bytes32(proof[0xa0:0xc0])),
            y_1: uint256(bytes32(proof[0xc0:0xe0]))
        });

        p.w2 = Honk.G1ProofPoint({
            x_0: uint256(bytes32(proof[0xe0:0x100])),
            x_1: uint256(bytes32(proof[0x100:0x120])),
            y_0: uint256(bytes32(proof[0x120:0x140])),
            y_1: uint256(bytes32(proof[0x140:0x160]))
        });
        p.w3 = Honk.G1ProofPoint({
            x_0: uint256(bytes32(proof[0x160:0x180])),
            x_1: uint256(bytes32(proof[0x180:0x1a0])),
            y_0: uint256(bytes32(proof[0x1a0:0x1c0])),
            y_1: uint256(bytes32(proof[0x1c0:0x1e0]))
        });

        // Lookup / Permutation Helper Commitments
        p.lookupReadCounts = Honk.G1ProofPoint({
            x_0: uint256(bytes32(proof[0x1e0:0x200])),
            x_1: uint256(bytes32(proof[0x200:0x220])),
            y_0: uint256(bytes32(proof[0x220:0x240])),
            y_1: uint256(bytes32(proof[0x240:0x260]))
        });
        p.lookupReadTags = Honk.G1ProofPoint({
            x_0: uint256(bytes32(proof[0x260:0x280])),
            x_1: uint256(bytes32(proof[0x280:0x2a0])),
            y_0: uint256(bytes32(proof[0x2a0:0x2c0])),
            y_1: uint256(bytes32(proof[0x2c0:0x2e0]))
        });
        p.w4 = Honk.G1ProofPoint({
            x_0: uint256(bytes32(proof[0x2e0:0x300])),
            x_1: uint256(bytes32(proof[0x300:0x320])),
            y_0: uint256(bytes32(proof[0x320:0x340])),
            y_1: uint256(bytes32(proof[0x340:0x360]))
        });
        p.lookupInverses = Honk.G1ProofPoint({
            x_0: uint256(bytes32(proof[0x360:0x380])),
            x_1: uint256(bytes32(proof[0x380:0x3a0])),
            y_0: uint256(bytes32(proof[0x3a0:0x3c0])),
            y_1: uint256(bytes32(proof[0x3c0:0x3e0]))
        });
        p.zPerm = Honk.G1ProofPoint({
            x_0: uint256(bytes32(proof[0x3e0:0x400])),
            x_1: uint256(bytes32(proof[0x400:0x420])),
            y_0: uint256(bytes32(proof[0x420:0x440])),
            y_1: uint256(bytes32(proof[0x440:0x460]))
        });

        // Boundary represents a pointer to the head of the unread part of the proof
        uint256 boundary = 0x460;

        // Sumcheck univariates
        for (uint256 i = 0; i < CONST_PROOF_SIZE_LOG_N; i++) {
            // The loop boundary of i, this will shift forward on each evaluation
            uint256 loop_boundary = boundary + (i * 0x20 * BATCHED_RELATION_PARTIAL_LENGTH);

            for (uint256 j = 0; j < BATCHED_RELATION_PARTIAL_LENGTH; j++) {
                uint256 start = loop_boundary + (j * 0x20);
                uint256 end = start + 0x20;
                p.sumcheckUnivariates[i][j] = FrLib.fromBytes32(bytes32(proof[start:end]));
            }
        }

        boundary = boundary + (CONST_PROOF_SIZE_LOG_N * BATCHED_RELATION_PARTIAL_LENGTH * 0x20);
        // Sumcheck evaluations
        for (uint256 i = 0; i < NUMBER_OF_ENTITIES; i++) {
            uint256 start = boundary + (i * 0x20);
            uint256 end = start + 0x20;
            p.sumcheckEvaluations[i] = FrLib.fromBytes32(bytes32(proof[start:end]));
        }

        boundary = boundary + (NUMBER_OF_ENTITIES * 0x20);

        // Gemini
        // Read gemini fold univariates
        for (uint256 i = 0; i < CONST_PROOF_SIZE_LOG_N - 1; i++) {
            uint256 xStart = boundary + (i * 0x80);
            uint256 xEnd = xStart + 0x20;

            uint256 x1Start = xEnd;
            uint256 x1End = x1Start + 0x20;

            uint256 yStart = x1End;
            uint256 yEnd = yStart + 0x20;

            uint256 y1Start = yEnd;
            uint256 y1End = y1Start + 0x20;
            p.geminiFoldComms[i] = Honk.G1ProofPoint({
                x_0: uint256(bytes32(proof[xStart:xEnd])),
                x_1: uint256(bytes32(proof[x1Start:x1End])),
                y_0: uint256(bytes32(proof[yStart:yEnd])),
                y_1: uint256(bytes32(proof[y1Start:y1End]))
            });
        }

        boundary = boundary + ((CONST_PROOF_SIZE_LOG_N - 1) * 0x80);

        // Read gemini a evaluations
        for (uint256 i = 0; i < CONST_PROOF_SIZE_LOG_N; i++) {
            uint256 start = boundary + (i * 0x20);
            uint256 end = start + 0x20;
            p.geminiAEvaluations[i] = FrLib.fromBytes32(bytes32(proof[start:end]));
        }

        boundary = boundary + (CONST_PROOF_SIZE_LOG_N * 0x20);

        // Shplonk
        p.shplonkQ = Honk.G1ProofPoint({
            x_0: uint256(bytes32(proof[boundary:boundary + 0x20])),
            x_1: uint256(bytes32(proof[boundary + 0x20:boundary + 0x40])),
            y_0: uint256(bytes32(proof[boundary + 0x40:boundary + 0x60])),
            y_1: uint256(bytes32(proof[boundary + 0x60:boundary + 0x80]))
        });

        boundary = boundary + 0x80;

        // KZG
        p.kzgQuotient = Honk.G1ProofPoint({
            x_0: uint256(bytes32(proof[boundary:boundary + 0x20])),
            x_1: uint256(bytes32(proof[boundary + 0x20:boundary + 0x40])),
            y_0: uint256(bytes32(proof[boundary + 0x40:boundary + 0x60])),
            y_1: uint256(bytes32(proof[boundary + 0x60:boundary + 0x80]))
        });

        return p;
    }
}

// EC Point utilities
function convertProofPoint(Honk.G1ProofPoint memory input) pure returns (Honk.G1Point memory) {
    return Honk.G1Point({x: input.x_0 | (input.x_1 << 136), y: input.y_0 | (input.y_1 << 136)});
}

function ecMul(Honk.G1Point memory point, Fr scalar) view returns (Honk.G1Point memory) {
    bytes memory input = abi.encodePacked(point.x, point.y, Fr.unwrap(scalar));
    (bool success, bytes memory result) = address(0x07).staticcall(input);
    require(success, "ecMul failed");

    (uint256 x, uint256 y) = abi.decode(result, (uint256, uint256));
    return Honk.G1Point({x: x, y: y});
}

function ecAdd(Honk.G1Point memory point0, Honk.G1Point memory point1) view returns (Honk.G1Point memory) {
    bytes memory input = abi.encodePacked(point0.x, point0.y, point1.x, point1.y);
    (bool success, bytes memory result) = address(0x06).staticcall(input);
    require(success, "ecAdd failed");

    (uint256 x, uint256 y) = abi.decode(result, (uint256, uint256));
    return Honk.G1Point({x: x, y: y});
}

function ecSub(Honk.G1Point memory point0, Honk.G1Point memory point1) view returns (Honk.G1Point memory) {
    // We negate the second point
    uint256 negativePoint1Y = (Q - point1.y) % Q;
    bytes memory input = abi.encodePacked(point0.x, point0.y, point1.x, negativePoint1Y);
    (bool success, bytes memory result) = address(0x06).staticcall(input);
    require(success, "ecAdd failed");

    (uint256 x, uint256 y) = abi.decode(result, (uint256, uint256));
    return Honk.G1Point({x: x, y: y});
}

function negateInplace(Honk.G1Point memory point) pure returns (Honk.G1Point memory) {
    point.y = (Q - point.y) % Q;
    return point;
}


library RelationsLib {
    Fr internal constant GRUMPKIN_CURVE_B_PARAMETER_NEGATED = Fr.wrap(17); // -(-17)

    function accumulateRelationEvaluations(Honk.Proof memory proof, Transcript memory tp, Fr powPartialEval)
        internal
        pure
        returns (Fr accumulator)
    {
        Fr[NUMBER_OF_ENTITIES] memory purportedEvaluations = proof.sumcheckEvaluations;
        Fr[NUMBER_OF_SUBRELATIONS] memory evaluations;

        // Accumulate all relations in Ultra Honk - each with varying number of subrelations
        accumulateArithmeticRelation(purportedEvaluations, evaluations, powPartialEval);
        accumulatePermutationRelation(purportedEvaluations, tp, evaluations, powPartialEval);
        accumulateLogDerivativeLookupRelation(purportedEvaluations, tp, evaluations, powPartialEval);
        accumulateDeltaRangeRelation(purportedEvaluations, evaluations, powPartialEval);
        accumulateEllipticRelation(purportedEvaluations, evaluations, powPartialEval);
        accumulateAuxillaryRelation(purportedEvaluations, tp, evaluations, powPartialEval);
        accumulatePoseidonExternalRelation(purportedEvaluations, evaluations, powPartialEval);
        accumulatePoseidonInternalRelation(purportedEvaluations, evaluations, powPartialEval);
        // batch the subrelations with the alpha challenges to obtain the full honk relation
        accumulator = scaleAndBatchSubrelations(evaluations, tp.alphas);
    }

    /**
     * Aesthetic helper function that is used to index by enum into proof.sumcheckEvaluations, it avoids
     * the relation checking code being cluttered with uint256 type casting, which is often a different colour in code
     * editors, and thus is noisy.
     */
    function wire(Fr[NUMBER_OF_ENTITIES] memory p, WIRE _wire) internal pure returns (Fr) {
        return p[uint256(_wire)];
    }

    uint256 internal constant NEG_HALF_MODULO_P = 0x183227397098d014dc2822db40c0ac2e9419f4243cdcb848a1f0fac9f8000000;
    /**
     * Ultra Arithmetic Relation
     *
     */
    function accumulateArithmeticRelation(
        Fr[NUMBER_OF_ENTITIES] memory p,
        Fr[NUMBER_OF_SUBRELATIONS] memory evals,
        Fr domainSep
    ) internal pure {
        // Relation 0
        Fr q_arith = wire(p, WIRE.Q_ARITH);
        {
            Fr neg_half = Fr.wrap(NEG_HALF_MODULO_P);

            Fr accum = (q_arith - Fr.wrap(3)) * (wire(p, WIRE.Q_M) * wire(p, WIRE.W_R) * wire(p, WIRE.W_L)) * neg_half;
            accum = accum + (wire(p, WIRE.Q_L) * wire(p, WIRE.W_L)) + (wire(p, WIRE.Q_R) * wire(p, WIRE.W_R))
                + (wire(p, WIRE.Q_O) * wire(p, WIRE.W_O)) + (wire(p, WIRE.Q_4) * wire(p, WIRE.W_4)) + wire(p, WIRE.Q_C);
            accum = accum + (q_arith - Fr.wrap(1)) * wire(p, WIRE.W_4_SHIFT);
            accum = accum * q_arith;
            accum = accum * domainSep;
            evals[0] = accum;
        }

        // Relation 1
        {
            Fr accum = wire(p, WIRE.W_L) + wire(p, WIRE.W_4) - wire(p, WIRE.W_L_SHIFT) + wire(p, WIRE.Q_M);
            accum = accum * (q_arith - Fr.wrap(2));
            accum = accum * (q_arith - Fr.wrap(1));
            accum = accum * q_arith;
            accum = accum * domainSep;
            evals[1] = accum;
        }
    }

    function accumulatePermutationRelation(
        Fr[NUMBER_OF_ENTITIES] memory p,
        Transcript memory tp,
        Fr[NUMBER_OF_SUBRELATIONS] memory evals,
        Fr domainSep
    ) internal pure {
        Fr grand_product_numerator;
        Fr grand_product_denominator;

        {
            Fr num = wire(p, WIRE.W_L) + wire(p, WIRE.ID_1) * tp.beta + tp.gamma;
            num = num * (wire(p, WIRE.W_R) + wire(p, WIRE.ID_2) * tp.beta + tp.gamma);
            num = num * (wire(p, WIRE.W_O) + wire(p, WIRE.ID_3) * tp.beta + tp.gamma);
            num = num * (wire(p, WIRE.W_4) + wire(p, WIRE.ID_4) * tp.beta + tp.gamma);

            grand_product_numerator = num;
        }
        {
            Fr den = wire(p, WIRE.W_L) + wire(p, WIRE.SIGMA_1) * tp.beta + tp.gamma;
            den = den * (wire(p, WIRE.W_R) + wire(p, WIRE.SIGMA_2) * tp.beta + tp.gamma);
            den = den * (wire(p, WIRE.W_O) + wire(p, WIRE.SIGMA_3) * tp.beta + tp.gamma);
            den = den * (wire(p, WIRE.W_4) + wire(p, WIRE.SIGMA_4) * tp.beta + tp.gamma);

            grand_product_denominator = den;
        }

        // Contribution 2
        {
            Fr acc = (wire(p, WIRE.Z_PERM) + wire(p, WIRE.LAGRANGE_FIRST)) * grand_product_numerator;

            acc = acc
                - (
                    (wire(p, WIRE.Z_PERM_SHIFT) + (wire(p, WIRE.LAGRANGE_LAST) * tp.publicInputsDelta))
                        * grand_product_denominator
                );
            acc = acc * domainSep;
            evals[2] = acc;
        }

        // Contribution 3
        {
            Fr acc = (wire(p, WIRE.LAGRANGE_LAST) * wire(p, WIRE.Z_PERM_SHIFT)) * domainSep;
            evals[3] = acc;
        }
    }

    function accumulateLogDerivativeLookupRelation(
        Fr[NUMBER_OF_ENTITIES] memory p,
        Transcript memory tp,
        Fr[NUMBER_OF_SUBRELATIONS] memory evals,
        Fr domainSep
    ) internal pure {
        Fr write_term;
        Fr read_term;

        // Calculate the write term (the table accumulation)
        {
            write_term = wire(p, WIRE.TABLE_1) + tp.gamma + (wire(p, WIRE.TABLE_2) * tp.eta)
                + (wire(p, WIRE.TABLE_3) * tp.etaTwo) + (wire(p, WIRE.TABLE_4) * tp.etaThree);
        }

        // Calculate the write term
        {
            Fr derived_entry_1 = wire(p, WIRE.W_L) + tp.gamma + (wire(p, WIRE.Q_R) * wire(p, WIRE.W_L_SHIFT));
            Fr derived_entry_2 = wire(p, WIRE.W_R) + wire(p, WIRE.Q_M) * wire(p, WIRE.W_R_SHIFT);
            Fr derived_entry_3 = wire(p, WIRE.W_O) + wire(p, WIRE.Q_C) * wire(p, WIRE.W_O_SHIFT);

            read_term = derived_entry_1 + (derived_entry_2 * tp.eta) + (derived_entry_3 * tp.etaTwo)
                + (wire(p, WIRE.Q_O) * tp.etaThree);
        }

        Fr read_inverse = wire(p, WIRE.LOOKUP_INVERSES) * write_term;
        Fr write_inverse = wire(p, WIRE.LOOKUP_INVERSES) * read_term;

        Fr inverse_exists_xor = wire(p, WIRE.LOOKUP_READ_TAGS) + wire(p, WIRE.Q_LOOKUP)
            - (wire(p, WIRE.LOOKUP_READ_TAGS) * wire(p, WIRE.Q_LOOKUP));

        // Inverse calculated correctly relation
        Fr accumulatorNone = read_term * write_term * wire(p, WIRE.LOOKUP_INVERSES) - inverse_exists_xor;
        accumulatorNone = accumulatorNone * domainSep;

        // Inverse
        Fr accumulatorOne = wire(p, WIRE.Q_LOOKUP) * read_inverse - wire(p, WIRE.LOOKUP_READ_COUNTS) * write_inverse;

        evals[4] = accumulatorNone;
        evals[5] = accumulatorOne;
    }

    function accumulateDeltaRangeRelation(
        Fr[NUMBER_OF_ENTITIES] memory p,
        Fr[NUMBER_OF_SUBRELATIONS] memory evals,
        Fr domainSep
    ) internal pure {
        Fr minus_one = Fr.wrap(0) - Fr.wrap(1);
        Fr minus_two = Fr.wrap(0) - Fr.wrap(2);
        Fr minus_three = Fr.wrap(0) - Fr.wrap(3);

        // Compute wire differences
        Fr delta_1 = wire(p, WIRE.W_R) - wire(p, WIRE.W_L);
        Fr delta_2 = wire(p, WIRE.W_O) - wire(p, WIRE.W_R);
        Fr delta_3 = wire(p, WIRE.W_4) - wire(p, WIRE.W_O);
        Fr delta_4 = wire(p, WIRE.W_L_SHIFT) - wire(p, WIRE.W_4);

        // Contribution 6
        {
            Fr acc = delta_1;
            acc = acc * (delta_1 + minus_one);
            acc = acc * (delta_1 + minus_two);
            acc = acc * (delta_1 + minus_three);
            acc = acc * wire(p, WIRE.Q_RANGE);
            acc = acc * domainSep;
            evals[6] = acc;
        }

        // Contribution 7
        {
            Fr acc = delta_2;
            acc = acc * (delta_2 + minus_one);
            acc = acc * (delta_2 + minus_two);
            acc = acc * (delta_2 + minus_three);
            acc = acc * wire(p, WIRE.Q_RANGE);
            acc = acc * domainSep;
            evals[7] = acc;
        }

        // Contribution 8
        {
            Fr acc = delta_3;
            acc = acc * (delta_3 + minus_one);
            acc = acc * (delta_3 + minus_two);
            acc = acc * (delta_3 + minus_three);
            acc = acc * wire(p, WIRE.Q_RANGE);
            acc = acc * domainSep;
            evals[8] = acc;
        }

        // Contribution 9
        {
            Fr acc = delta_4;
            acc = acc * (delta_4 + minus_one);
            acc = acc * (delta_4 + minus_two);
            acc = acc * (delta_4 + minus_three);
            acc = acc * wire(p, WIRE.Q_RANGE);
            acc = acc * domainSep;
            evals[9] = acc;
        }
    }

    struct EllipticParams {
        // Points
        Fr x_1;
        Fr y_1;
        Fr x_2;
        Fr y_2;
        Fr y_3;
        Fr x_3;
        // push accumulators into memory
        Fr x_double_identity;
    }

    function accumulateEllipticRelation(
        Fr[NUMBER_OF_ENTITIES] memory p,
        Fr[NUMBER_OF_SUBRELATIONS] memory evals,
        Fr domainSep
    ) internal pure {
        EllipticParams memory ep;
        ep.x_1 = wire(p, WIRE.W_R);
        ep.y_1 = wire(p, WIRE.W_O);

        ep.x_2 = wire(p, WIRE.W_L_SHIFT);
        ep.y_2 = wire(p, WIRE.W_4_SHIFT);
        ep.y_3 = wire(p, WIRE.W_O_SHIFT);
        ep.x_3 = wire(p, WIRE.W_R_SHIFT);

        Fr q_sign = wire(p, WIRE.Q_L);
        Fr q_is_double = wire(p, WIRE.Q_M);

        // Contribution 10 point addition, x-coordinate check
        // q_elliptic * (x3 + x2 + x1)(x2 - x1)(x2 - x1) - y2^2 - y1^2 + 2(y2y1)*q_sign = 0
        Fr x_diff = (ep.x_2 - ep.x_1);
        Fr y1_sqr = (ep.y_1 * ep.y_1);
        {
            // Move to top
            Fr partialEval = domainSep;

            Fr y2_sqr = (ep.y_2 * ep.y_2);
            Fr y1y2 = ep.y_1 * ep.y_2 * q_sign;
            Fr x_add_identity = (ep.x_3 + ep.x_2 + ep.x_1);
            x_add_identity = x_add_identity * x_diff * x_diff;
            x_add_identity = x_add_identity - y2_sqr - y1_sqr + y1y2 + y1y2;

            evals[10] = x_add_identity * partialEval * wire(p, WIRE.Q_ELLIPTIC) * (Fr.wrap(1) - q_is_double);
        }

        // Contribution 11 point addition, x-coordinate check
        // q_elliptic * (q_sign * y1 + y3)(x2 - x1) + (x3 - x1)(y2 - q_sign * y1) = 0
        {
            Fr y1_plus_y3 = ep.y_1 + ep.y_3;
            Fr y_diff = ep.y_2 * q_sign - ep.y_1;
            Fr y_add_identity = y1_plus_y3 * x_diff + (ep.x_3 - ep.x_1) * y_diff;
            evals[11] = y_add_identity * domainSep * wire(p, WIRE.Q_ELLIPTIC) * (Fr.wrap(1) - q_is_double);
        }

        // Contribution 10 point doubling, x-coordinate check
        // (x3 + x1 + x1) (4y1*y1) - 9 * x1 * x1 * x1 * x1 = 0
        // N.B. we're using the equivalence x1*x1*x1 === y1*y1 - curve_b to reduce degree by 1
        {
            Fr x_pow_4 = (y1_sqr + GRUMPKIN_CURVE_B_PARAMETER_NEGATED) * ep.x_1;
            Fr y1_sqr_mul_4 = y1_sqr + y1_sqr;
            y1_sqr_mul_4 = y1_sqr_mul_4 + y1_sqr_mul_4;
            Fr x1_pow_4_mul_9 = x_pow_4 * Fr.wrap(9);

            // NOTE: pushed into memory (stack >:'( )
            ep.x_double_identity = (ep.x_3 + ep.x_1 + ep.x_1) * y1_sqr_mul_4 - x1_pow_4_mul_9;

            Fr acc = ep.x_double_identity * domainSep * wire(p, WIRE.Q_ELLIPTIC) * q_is_double;
            evals[10] = evals[10] + acc;
        }

        // Contribution 11 point doubling, y-coordinate check
        // (y1 + y1) (2y1) - (3 * x1 * x1)(x1 - x3) = 0
        {
            Fr x1_sqr_mul_3 = (ep.x_1 + ep.x_1 + ep.x_1) * ep.x_1;
            Fr y_double_identity = x1_sqr_mul_3 * (ep.x_1 - ep.x_3) - (ep.y_1 + ep.y_1) * (ep.y_1 + ep.y_3);
            evals[11] = evals[11] + y_double_identity * domainSep * wire(p, WIRE.Q_ELLIPTIC) * q_is_double;
        }
    }

    // Constants for the auxiliary relation
    Fr constant LIMB_SIZE = Fr.wrap(uint256(1) << 68);
    Fr constant SUBLIMB_SHIFT = Fr.wrap(uint256(1) << 14);

    // Parameters used within the Auxiliary Relation
    // A struct is used to work around stack too deep. This relation has alot of variables
    struct AuxParams {
        Fr limb_subproduct;
        Fr non_native_field_gate_1;
        Fr non_native_field_gate_2;
        Fr non_native_field_gate_3;
        Fr limb_accumulator_1;
        Fr limb_accumulator_2;
        Fr memory_record_check;
        Fr partial_record_check;
        Fr next_gate_access_type;
        Fr record_delta;
        Fr index_delta;
        Fr adjacent_values_match_if_adjacent_indices_match;
        Fr adjacent_values_match_if_adjacent_indices_match_and_next_access_is_a_read_operation;
        Fr access_check;
        Fr next_gate_access_type_is_boolean;
        Fr ROM_consistency_check_identity;
        Fr RAM_consistency_check_identity;
        Fr timestamp_delta;
        Fr RAM_timestamp_check_identity;
        Fr memory_identity;
        Fr index_is_monotonically_increasing;
        Fr auxiliary_identity;
    }

    function accumulateAuxillaryRelation(
        Fr[NUMBER_OF_ENTITIES] memory p,
        Transcript memory tp,
        Fr[NUMBER_OF_SUBRELATIONS] memory evals,
        Fr domainSep
    ) internal pure {
        AuxParams memory ap;

        /**
         * Contribution 12
         * Non native field arithmetic gate 2
         * deg 4
         *
         *             _                                                                               _
         *            /   _                   _                               _       14                \
         * q_2 . q_4 |   (w_1 . w_2) + (w_1 . w_2) + (w_1 . w_4 + w_2 . w_3 - w_3) . 2    - w_3 - w_4   |
         *            \_                                                                               _/
         *
         *
         */
        ap.limb_subproduct = wire(p, WIRE.W_L) * wire(p, WIRE.W_R_SHIFT) + wire(p, WIRE.W_L_SHIFT) * wire(p, WIRE.W_R);
        ap.non_native_field_gate_2 =
            (wire(p, WIRE.W_L) * wire(p, WIRE.W_4) + wire(p, WIRE.W_R) * wire(p, WIRE.W_O) - wire(p, WIRE.W_O_SHIFT));
        ap.non_native_field_gate_2 = ap.non_native_field_gate_2 * LIMB_SIZE;
        ap.non_native_field_gate_2 = ap.non_native_field_gate_2 - wire(p, WIRE.W_4_SHIFT);
        ap.non_native_field_gate_2 = ap.non_native_field_gate_2 + ap.limb_subproduct;
        ap.non_native_field_gate_2 = ap.non_native_field_gate_2 * wire(p, WIRE.Q_4);

        ap.limb_subproduct = ap.limb_subproduct * LIMB_SIZE;
        ap.limb_subproduct = ap.limb_subproduct + (wire(p, WIRE.W_L_SHIFT) * wire(p, WIRE.W_R_SHIFT));
        ap.non_native_field_gate_1 = ap.limb_subproduct;
        ap.non_native_field_gate_1 = ap.non_native_field_gate_1 - (wire(p, WIRE.W_O) + wire(p, WIRE.W_4));
        ap.non_native_field_gate_1 = ap.non_native_field_gate_1 * wire(p, WIRE.Q_O);

        ap.non_native_field_gate_3 = ap.limb_subproduct;
        ap.non_native_field_gate_3 = ap.non_native_field_gate_3 + wire(p, WIRE.W_4);
        ap.non_native_field_gate_3 = ap.non_native_field_gate_3 - (wire(p, WIRE.W_O_SHIFT) + wire(p, WIRE.W_4_SHIFT));
        ap.non_native_field_gate_3 = ap.non_native_field_gate_3 * wire(p, WIRE.Q_M);

        Fr non_native_field_identity =
            ap.non_native_field_gate_1 + ap.non_native_field_gate_2 + ap.non_native_field_gate_3;
        non_native_field_identity = non_native_field_identity * wire(p, WIRE.Q_R);

        // ((((w2' * 2^14 + w1') * 2^14 + w3) * 2^14 + w2) * 2^14 + w1 - w4) * qm
        // deg 2
        ap.limb_accumulator_1 = wire(p, WIRE.W_R_SHIFT) * SUBLIMB_SHIFT;
        ap.limb_accumulator_1 = ap.limb_accumulator_1 + wire(p, WIRE.W_L_SHIFT);
        ap.limb_accumulator_1 = ap.limb_accumulator_1 * SUBLIMB_SHIFT;
        ap.limb_accumulator_1 = ap.limb_accumulator_1 + wire(p, WIRE.W_O);
        ap.limb_accumulator_1 = ap.limb_accumulator_1 * SUBLIMB_SHIFT;
        ap.limb_accumulator_1 = ap.limb_accumulator_1 + wire(p, WIRE.W_R);
        ap.limb_accumulator_1 = ap.limb_accumulator_1 * SUBLIMB_SHIFT;
        ap.limb_accumulator_1 = ap.limb_accumulator_1 + wire(p, WIRE.W_L);
        ap.limb_accumulator_1 = ap.limb_accumulator_1 - wire(p, WIRE.W_4);
        ap.limb_accumulator_1 = ap.limb_accumulator_1 * wire(p, WIRE.Q_4);

        // ((((w3' * 2^14 + w2') * 2^14 + w1') * 2^14 + w4) * 2^14 + w3 - w4') * qm
        // deg 2
        ap.limb_accumulator_2 = wire(p, WIRE.W_O_SHIFT) * SUBLIMB_SHIFT;
        ap.limb_accumulator_2 = ap.limb_accumulator_2 + wire(p, WIRE.W_R_SHIFT);
        ap.limb_accumulator_2 = ap.limb_accumulator_2 * SUBLIMB_SHIFT;
        ap.limb_accumulator_2 = ap.limb_accumulator_2 + wire(p, WIRE.W_L_SHIFT);
        ap.limb_accumulator_2 = ap.limb_accumulator_2 * SUBLIMB_SHIFT;
        ap.limb_accumulator_2 = ap.limb_accumulator_2 + wire(p, WIRE.W_4);
        ap.limb_accumulator_2 = ap.limb_accumulator_2 * SUBLIMB_SHIFT;
        ap.limb_accumulator_2 = ap.limb_accumulator_2 + wire(p, WIRE.W_O);
        ap.limb_accumulator_2 = ap.limb_accumulator_2 - wire(p, WIRE.W_4_SHIFT);
        ap.limb_accumulator_2 = ap.limb_accumulator_2 * wire(p, WIRE.Q_M);

        Fr limb_accumulator_identity = ap.limb_accumulator_1 + ap.limb_accumulator_2;
        limb_accumulator_identity = limb_accumulator_identity * wire(p, WIRE.Q_O); //  deg 3

        /**
         * MEMORY
         *
         * A RAM memory record contains a tuple of the following fields:
         *  * i: `index` of memory cell being accessed
         *  * t: `timestamp` of memory cell being accessed (used for RAM, set to 0 for ROM)
         *  * v: `value` of memory cell being accessed
         *  * a: `access` type of record. read: 0 = read, 1 = write
         *  * r: `record` of memory cell. record = access + index * eta + timestamp * eta_two + value * eta_three
         *
         * A ROM memory record contains a tuple of the following fields:
         *  * i: `index` of memory cell being accessed
         *  * v: `value1` of memory cell being accessed (ROM tables can store up to 2 values per index)
         *  * v2:`value2` of memory cell being accessed (ROM tables can store up to 2 values per index)
         *  * r: `record` of memory cell. record = index * eta + value2 * eta_two + value1 * eta_three
         *
         *  When performing a read/write access, the values of i, t, v, v2, a, r are stored in the following wires +
         * selectors, depending on whether the gate is a RAM read/write or a ROM read
         *
         *  | gate type | i  | v2/t  |  v | a  | r  |
         *  | --------- | -- | ----- | -- | -- | -- |
         *  | ROM       | w1 | w2    | w3 | -- | w4 |
         *  | RAM       | w1 | w2    | w3 | qc | w4 |
         *
         * (for accesses where `index` is a circuit constant, it is assumed the circuit will apply a copy constraint on
         * `w2` to fix its value)
         *
         *
         */

        /**
         * Memory Record Check
         * Partial degree: 1
         * Total degree: 4
         *
         * A ROM/ROM access gate can be evaluated with the identity:
         *
         * qc + w1 \eta + w2 \eta_two + w3 \eta_three - w4 = 0
         *
         * For ROM gates, qc = 0
         */
        ap.memory_record_check = wire(p, WIRE.W_O) * tp.etaThree;
        ap.memory_record_check = ap.memory_record_check + (wire(p, WIRE.W_R) * tp.etaTwo);
        ap.memory_record_check = ap.memory_record_check + (wire(p, WIRE.W_L) * tp.eta);
        ap.memory_record_check = ap.memory_record_check + wire(p, WIRE.Q_C);
        ap.partial_record_check = ap.memory_record_check; // used in RAM consistency check; deg 1 or 4
        ap.memory_record_check = ap.memory_record_check - wire(p, WIRE.W_4);

        /**
         * Contribution 13 & 14
         * ROM Consistency Check
         * Partial degree: 1
         * Total degree: 4
         *
         * For every ROM read, a set equivalence check is applied between the record witnesses, and a second set of
         * records that are sorted.
         *
         * We apply the following checks for the sorted records:
         *
         * 1. w1, w2, w3 correctly map to 'index', 'v1, 'v2' for a given record value at w4
         * 2. index values for adjacent records are monotonically increasing
         * 3. if, at gate i, index_i == index_{i + 1}, then value1_i == value1_{i + 1} and value2_i == value2_{i + 1}
         *
         */
        ap.index_delta = wire(p, WIRE.W_L_SHIFT) - wire(p, WIRE.W_L);
        ap.record_delta = wire(p, WIRE.W_4_SHIFT) - wire(p, WIRE.W_4);

        ap.index_is_monotonically_increasing = ap.index_delta * ap.index_delta - ap.index_delta; // deg 2

        ap.adjacent_values_match_if_adjacent_indices_match = (ap.index_delta * MINUS_ONE + Fr.wrap(1)) * ap.record_delta; // deg 2

        evals[13] = ap.adjacent_values_match_if_adjacent_indices_match * (wire(p, WIRE.Q_L) * wire(p, WIRE.Q_R))
            * (wire(p, WIRE.Q_AUX) * domainSep); // deg 5
        evals[14] = ap.index_is_monotonically_increasing * (wire(p, WIRE.Q_L) * wire(p, WIRE.Q_R))
            * (wire(p, WIRE.Q_AUX) * domainSep); // deg 5

        ap.ROM_consistency_check_identity = ap.memory_record_check * (wire(p, WIRE.Q_L) * wire(p, WIRE.Q_R)); // deg 3 or 7

        /**
         * Contributions 15,16,17
         * RAM Consistency Check
         *
         * The 'access' type of the record is extracted with the expression `w_4 - ap.partial_record_check`
         * (i.e. for an honest Prover `w1 * eta + w2 * eta^2 + w3 * eta^3 - w4 = access`.
         * This is validated by requiring `access` to be boolean
         *
         * For two adjacent entries in the sorted list if _both_
         *  A) index values match
         *  B) adjacent access value is 0 (i.e. next gate is a READ)
         * then
         *  C) both values must match.
         * The gate boolean check is
         * (A && B) => C  === !(A && B) || C ===  !A || !B || C
         *
         * N.B. it is the responsibility of the circuit writer to ensure that every RAM cell is initialized
         * with a WRITE operation.
         */
        Fr access_type = (wire(p, WIRE.W_4) - ap.partial_record_check); // will be 0 or 1 for honest Prover; deg 1 or 4
        ap.access_check = access_type * access_type - access_type; // check value is 0 or 1; deg 2 or 8

        ap.next_gate_access_type = wire(p, WIRE.W_O_SHIFT) * tp.etaThree;
        ap.next_gate_access_type = ap.next_gate_access_type + (wire(p, WIRE.W_R_SHIFT) * tp.etaTwo);
        ap.next_gate_access_type = ap.next_gate_access_type + (wire(p, WIRE.W_L_SHIFT) * tp.eta);
        ap.next_gate_access_type = wire(p, WIRE.W_4_SHIFT) - ap.next_gate_access_type;

        Fr value_delta = wire(p, WIRE.W_O_SHIFT) - wire(p, WIRE.W_O);
        ap.adjacent_values_match_if_adjacent_indices_match_and_next_access_is_a_read_operation = (
            ap.index_delta * MINUS_ONE + Fr.wrap(1)
        ) * value_delta * (ap.next_gate_access_type * MINUS_ONE + Fr.wrap(1)); // deg 3 or 6

        // We can't apply the RAM consistency check identity on the final entry in the sorted list (the wires in the
        // next gate would make the identity fail).  We need to validate that its 'access type' bool is correct. Can't
        // do  with an arithmetic gate because of the  `eta` factors. We need to check that the *next* gate's access
        // type is  correct, to cover this edge case
        // deg 2 or 4
        ap.next_gate_access_type_is_boolean =
            ap.next_gate_access_type * ap.next_gate_access_type - ap.next_gate_access_type;

        // Putting it all together...
        evals[15] = ap.adjacent_values_match_if_adjacent_indices_match_and_next_access_is_a_read_operation
            * (wire(p, WIRE.Q_ARITH)) * (wire(p, WIRE.Q_AUX) * domainSep); // deg 5 or 8
        evals[16] = ap.index_is_monotonically_increasing * (wire(p, WIRE.Q_ARITH)) * (wire(p, WIRE.Q_AUX) * domainSep); // deg 4
        evals[17] = ap.next_gate_access_type_is_boolean * (wire(p, WIRE.Q_ARITH)) * (wire(p, WIRE.Q_AUX) * domainSep); // deg 4 or 6

        ap.RAM_consistency_check_identity = ap.access_check * (wire(p, WIRE.Q_ARITH)); // deg 3 or 9

        /**
         * RAM Timestamp Consistency Check
         *
         * | w1 | w2 | w3 | w4 |
         * | index | timestamp | timestamp_check | -- |
         *
         * Let delta_index = index_{i + 1} - index_{i}
         *
         * Iff delta_index == 0, timestamp_check = timestamp_{i + 1} - timestamp_i
         * Else timestamp_check = 0
         */
        ap.timestamp_delta = wire(p, WIRE.W_R_SHIFT) - wire(p, WIRE.W_R);
        ap.RAM_timestamp_check_identity =
            (ap.index_delta * MINUS_ONE + Fr.wrap(1)) * ap.timestamp_delta - wire(p, WIRE.W_O); // deg 3

        /**
         * Complete Contribution 12
         * The complete RAM/ROM memory identity
         * Partial degree:
         */
        ap.memory_identity = ap.ROM_consistency_check_identity; // deg 3 or 6
        ap.memory_identity =
            ap.memory_identity + ap.RAM_timestamp_check_identity * (wire(p, WIRE.Q_4) * wire(p, WIRE.Q_L)); // deg 4
        ap.memory_identity = ap.memory_identity + ap.memory_record_check * (wire(p, WIRE.Q_M) * wire(p, WIRE.Q_L)); // deg 3 or 6
        ap.memory_identity = ap.memory_identity + ap.RAM_consistency_check_identity; // deg 3 or 9

        // (deg 3 or 9) + (deg 4) + (deg 3)
        ap.auxiliary_identity = ap.memory_identity + non_native_field_identity + limb_accumulator_identity;
        ap.auxiliary_identity = ap.auxiliary_identity * (wire(p, WIRE.Q_AUX) * domainSep); // deg 4 or 10
        evals[12] = ap.auxiliary_identity;
    }

    struct PoseidonExternalParams {
        Fr s1;
        Fr s2;
        Fr s3;
        Fr s4;
        Fr u1;
        Fr u2;
        Fr u3;
        Fr u4;
        Fr t0;
        Fr t1;
        Fr t2;
        Fr t3;
        Fr v1;
        Fr v2;
        Fr v3;
        Fr v4;
        Fr q_pos_by_scaling;
    }

    function accumulatePoseidonExternalRelation(
        Fr[NUMBER_OF_ENTITIES] memory p,
        Fr[NUMBER_OF_SUBRELATIONS] memory evals,
        Fr domainSep
    ) internal pure {
        PoseidonExternalParams memory ep;

        ep.s1 = wire(p, WIRE.W_L) + wire(p, WIRE.Q_L);
        ep.s2 = wire(p, WIRE.W_R) + wire(p, WIRE.Q_R);
        ep.s3 = wire(p, WIRE.W_O) + wire(p, WIRE.Q_O);
        ep.s4 = wire(p, WIRE.W_4) + wire(p, WIRE.Q_4);

        ep.u1 = ep.s1 * ep.s1 * ep.s1 * ep.s1 * ep.s1;
        ep.u2 = ep.s2 * ep.s2 * ep.s2 * ep.s2 * ep.s2;
        ep.u3 = ep.s3 * ep.s3 * ep.s3 * ep.s3 * ep.s3;
        ep.u4 = ep.s4 * ep.s4 * ep.s4 * ep.s4 * ep.s4;
        // matrix mul v = M_E * u with 14 additions
        ep.t0 = ep.u1 + ep.u2; // u_1 + u_2
        ep.t1 = ep.u3 + ep.u4; // u_3 + u_4
        ep.t2 = ep.u2 + ep.u2 + ep.t1; // 2u_2
        // ep.t2 += ep.t1; // 2u_2 + u_3 + u_4
        ep.t3 = ep.u4 + ep.u4 + ep.t0; // 2u_4
        // ep.t3 += ep.t0; // u_1 + u_2 + 2u_4
        ep.v4 = ep.t1 + ep.t1;
        ep.v4 = ep.v4 + ep.v4 + ep.t3;
        // ep.v4 += ep.t3; // u_1 + u_2 + 4u_3 + 6u_4
        ep.v2 = ep.t0 + ep.t0;
        ep.v2 = ep.v2 + ep.v2 + ep.t2;
        // ep.v2 += ep.t2; // 4u_1 + 6u_2 + u_3 + u_4
        ep.v1 = ep.t3 + ep.v2; // 5u_1 + 7u_2 + u_3 + 3u_4
        ep.v3 = ep.t2 + ep.v4; // u_1 + 3u_2 + 5u_3 + 7u_4

        ep.q_pos_by_scaling = wire(p, WIRE.Q_POSEIDON2_EXTERNAL) * domainSep;
        evals[18] = evals[18] + ep.q_pos_by_scaling * (ep.v1 - wire(p, WIRE.W_L_SHIFT));

        evals[19] = evals[19] + ep.q_pos_by_scaling * (ep.v2 - wire(p, WIRE.W_R_SHIFT));

        evals[20] = evals[20] + ep.q_pos_by_scaling * (ep.v3 - wire(p, WIRE.W_O_SHIFT));

        evals[21] = evals[21] + ep.q_pos_by_scaling * (ep.v4 - wire(p, WIRE.W_4_SHIFT));
    }

    struct PoseidonInternalParams {
        Fr u1;
        Fr u2;
        Fr u3;
        Fr u4;
        Fr u_sum;
        Fr v1;
        Fr v2;
        Fr v3;
        Fr v4;
        Fr s1;
        Fr q_pos_by_scaling;
    }

    function accumulatePoseidonInternalRelation(
        Fr[NUMBER_OF_ENTITIES] memory p,
        Fr[NUMBER_OF_SUBRELATIONS] memory evals,
        Fr domainSep
    ) internal pure {
        PoseidonInternalParams memory ip;

        Fr[4] memory INTERNAL_MATRIX_DIAGONAL = [
            FrLib.from(0x10dc6e9c006ea38b04b1e03b4bd9490c0d03f98929ca1d7fb56821fd19d3b6e7),
            FrLib.from(0x0c28145b6a44df3e0149b3d0a30b3bb599df9756d4dd9b84a86b38cfb45a740b),
            FrLib.from(0x00544b8338791518b2c7645a50392798b21f75bb60e3596170067d00141cac15),
            FrLib.from(0x222c01175718386f2e2e82eb122789e352e105a3b8fa852613bc534433ee428b)
        ];

        // add round constants
        ip.s1 = wire(p, WIRE.W_L) + wire(p, WIRE.Q_L);

        // apply s-box round
        ip.u1 = ip.s1 * ip.s1 * ip.s1 * ip.s1 * ip.s1;
        ip.u2 = wire(p, WIRE.W_R);
        ip.u3 = wire(p, WIRE.W_O);
        ip.u4 = wire(p, WIRE.W_4);

        // matrix mul with v = M_I * u 4 muls and 7 additions
        ip.u_sum = ip.u1 + ip.u2 + ip.u3 + ip.u4;

        ip.q_pos_by_scaling = wire(p, WIRE.Q_POSEIDON2_INTERNAL) * domainSep;

        ip.v1 = ip.u1 * INTERNAL_MATRIX_DIAGONAL[0] + ip.u_sum;
        evals[22] = evals[22] + ip.q_pos_by_scaling * (ip.v1 - wire(p, WIRE.W_L_SHIFT));

        ip.v2 = ip.u2 * INTERNAL_MATRIX_DIAGONAL[1] + ip.u_sum;
        evals[23] = evals[23] + ip.q_pos_by_scaling * (ip.v2 - wire(p, WIRE.W_R_SHIFT));

        ip.v3 = ip.u3 * INTERNAL_MATRIX_DIAGONAL[2] + ip.u_sum;
        evals[24] = evals[24] + ip.q_pos_by_scaling * (ip.v3 - wire(p, WIRE.W_O_SHIFT));

        ip.v4 = ip.u4 * INTERNAL_MATRIX_DIAGONAL[3] + ip.u_sum;
        evals[25] = evals[25] + ip.q_pos_by_scaling * (ip.v4 - wire(p, WIRE.W_4_SHIFT));
    }

    function scaleAndBatchSubrelations(
        Fr[NUMBER_OF_SUBRELATIONS] memory evaluations,
        Fr[NUMBER_OF_ALPHAS] memory subrelationChallenges
    ) internal pure returns (Fr accumulator) {
        accumulator = accumulator + evaluations[0];

        for (uint256 i = 1; i < NUMBER_OF_SUBRELATIONS; ++i) {
            accumulator = accumulator + evaluations[i] * subrelationChallenges[i - 1];
        }
    }
}

// Errors
error PublicInputsLengthWrong();
error SumcheckFailed();
error ShpleminiFailed();

interface IVerifier {
    function verify(bytes calldata _proof, bytes32[] calldata _publicInputs) external view returns (bool);
}

// Smart contract verifier of honk proofs
contract NoirRegisterIdentity_ID_Card_I_Honk is IVerifier
{
    using FrLib for Fr;

    function verify(bytes calldata proof, bytes32[] calldata publicInputs) public view override returns (bool) {
        Honk.VerificationKey memory vk = loadVerificationKey();
        Honk.Proof memory p = TranscriptLib.loadProof(proof);

        if (publicInputs.length != vk.publicInputsSize) {
            revert PublicInputsLengthWrong();
        }

        // Generate the fiat shamir challenges for the whole protocol
        Transcript memory t = TranscriptLib.generateTranscript(p, publicInputs, vk.publicInputsSize);

        // Compute the public input delta
        t.publicInputsDelta =
            computePublicInputDelta(publicInputs, t.beta, t.gamma, vk.circuitSize, p.publicInputsOffset);

        // Sumcheck
        bool sumcheckVerified = verifySumcheck(p, t);
        if (!sumcheckVerified) revert SumcheckFailed();

        bool shpleminiVerified = verifyShplemini(p, vk, t);
        if (!shpleminiVerified) revert ShpleminiFailed();

        return sumcheckVerified && shpleminiVerified; // Boolean condition not required - nice for vanity :)
    }

    function loadVerificationKey() internal pure returns (Honk.VerificationKey memory) {
        return HonkVerificationKey.loadVerificationKey();
    }

    function computePublicInputDelta(
        bytes32[] memory publicInputs,
        Fr beta,
        Fr gamma,
        uint256 domainSize,
        uint256 offset
    ) internal view returns (Fr publicInputDelta) {
        Fr numerator = Fr.wrap(1);
        Fr denominator = Fr.wrap(1);

        Fr numeratorAcc = gamma + (beta * FrLib.from(domainSize + offset));
        Fr denominatorAcc = gamma - (beta * FrLib.from(offset + 1));

        {
            for (uint256 i = 0; i < NUMBER_OF_PUBLIC_INPUTS; i++) {
                Fr pubInput = FrLib.fromBytes32(publicInputs[i]);

                numerator = numerator * (numeratorAcc + pubInput);
                denominator = denominator * (denominatorAcc + pubInput);

                numeratorAcc = numeratorAcc + beta;
                denominatorAcc = denominatorAcc - beta;
            }
        }

        // Fr delta = numerator / denominator; // TOOO: batch invert later?
        publicInputDelta = FrLib.div(numerator, denominator);
    }

    uint256 constant ROUND_TARGET = 0;

    function verifySumcheck(Honk.Proof memory proof, Transcript memory tp) internal view returns (bool verified) {
        Fr roundTarget;
        Fr powPartialEvaluation = Fr.wrap(1);

        // We perform sumcheck reductions over log n rounds ( the multivariate degree )
        for (uint256 round; round < LOG_N; ++round) {
            Fr[BATCHED_RELATION_PARTIAL_LENGTH] memory roundUnivariate = proof.sumcheckUnivariates[round];
            bool valid = checkSum(roundUnivariate, roundTarget);
            if (!valid) revert SumcheckFailed();

            Fr roundChallenge = tp.sumCheckUChallenges[round];

            // Update the round target for the next rounf
            roundTarget = computeNextTargetSum(roundUnivariate, roundChallenge);
            powPartialEvaluation = partiallyEvaluatePOW(tp, powPartialEvaluation, roundChallenge, round);
        }

        // Last round
        Fr grandHonkRelationSum = RelationsLib.accumulateRelationEvaluations(proof, tp, powPartialEvaluation);
        verified = (grandHonkRelationSum == roundTarget);
    }

    function checkSum(Fr[BATCHED_RELATION_PARTIAL_LENGTH] memory roundUnivariate, Fr roundTarget)
        internal
        pure
        returns (bool checked)
    {
        Fr totalSum = roundUnivariate[0] + roundUnivariate[1];
        checked = totalSum == roundTarget;
    }

    // Return the new target sum for the next sumcheck round
    function computeNextTargetSum(Fr[BATCHED_RELATION_PARTIAL_LENGTH] memory roundUnivariates, Fr roundChallenge)
        internal
        view
        returns (Fr targetSum)
    {
        Fr[BATCHED_RELATION_PARTIAL_LENGTH] memory BARYCENTRIC_LAGRANGE_DENOMINATORS = [
            Fr.wrap(0x30644e72e131a029b85045b68181585d2833e84879b9709143e1f593efffec51),
            Fr.wrap(0x00000000000000000000000000000000000000000000000000000000000002d0),
            Fr.wrap(0x30644e72e131a029b85045b68181585d2833e84879b9709143e1f593efffff11),
            Fr.wrap(0x0000000000000000000000000000000000000000000000000000000000000090),
            Fr.wrap(0x30644e72e131a029b85045b68181585d2833e84879b9709143e1f593efffff71),
            Fr.wrap(0x00000000000000000000000000000000000000000000000000000000000000f0),
            Fr.wrap(0x30644e72e131a029b85045b68181585d2833e84879b9709143e1f593effffd31),
            Fr.wrap(0x00000000000000000000000000000000000000000000000000000000000013b0)
        ];

        Fr[BATCHED_RELATION_PARTIAL_LENGTH] memory BARYCENTRIC_DOMAIN = [
            Fr.wrap(0x00),
            Fr.wrap(0x01),
            Fr.wrap(0x02),
            Fr.wrap(0x03),
            Fr.wrap(0x04),
            Fr.wrap(0x05),
            Fr.wrap(0x06),
            Fr.wrap(0x07)
        ];
        // To compute the next target sum, we evaluate the given univariate at a point u (challenge).

        // Performing Barycentric evaluations
        // Compute B(x)
        Fr numeratorValue = Fr.wrap(1);
        for (uint256 i; i < BATCHED_RELATION_PARTIAL_LENGTH; ++i) {
            numeratorValue = numeratorValue * (roundChallenge - Fr.wrap(i));
        }

        // Calculate domain size N of inverses
        Fr[BATCHED_RELATION_PARTIAL_LENGTH] memory denominatorInverses;
        for (uint256 i; i < BATCHED_RELATION_PARTIAL_LENGTH; ++i) {
            Fr inv = BARYCENTRIC_LAGRANGE_DENOMINATORS[i];
            inv = inv * (roundChallenge - BARYCENTRIC_DOMAIN[i]);
            inv = FrLib.invert(inv);
            denominatorInverses[i] = inv;
        }

        for (uint256 i; i < BATCHED_RELATION_PARTIAL_LENGTH; ++i) {
            Fr term = roundUnivariates[i];
            term = term * denominatorInverses[i];
            targetSum = targetSum + term;
        }

        // Scale the sum by the value of B(x)
        targetSum = targetSum * numeratorValue;
    }

    // Univariate evaluation of the monomial ((1-X_l) + X_l.B_l) at the challenge point X_l=u_l
    function partiallyEvaluatePOW(Transcript memory tp, Fr currentEvaluation, Fr roundChallenge, uint256 round)
        internal
        pure
        returns (Fr newEvaluation)
    {
        Fr univariateEval = Fr.wrap(1) + (roundChallenge * (tp.gateChallenges[round] - Fr.wrap(1)));
        newEvaluation = currentEvaluation * univariateEval;
    }

    // Avoid stack too deep
    struct ShpleminiIntermediates {
        // i-th unshifted commitment is multiplied by −ρⁱ and the unshifted_scalar ( 1/(z−r) + ν/(z+r) )
        Fr unshiftedScalar;
        // i-th shifted commitment is multiplied by −ρⁱ⁺ᵏ and the shifted_scalar r⁻¹ ⋅ (1/(z−r) − ν/(z+r))
        Fr shiftedScalar;
        // Scalar to be multiplied by [1]₁
        Fr constantTermAccumulator;
        // Accumulator for powers of rho
        Fr batchingChallenge;
        // Linear combination of multilinear (sumcheck) evaluations and powers of rho
        Fr batchedEvaluation;
    }

    function verifyShplemini(Honk.Proof memory proof, Honk.VerificationKey memory vk, Transcript memory tp)
        internal
        view
        returns (bool verified)
    {
        ShpleminiIntermediates memory mem; // stack

        // - Compute vector (r, r², ... , r²⁽ⁿ⁻¹⁾), where n = log_circuit_size, I think this should be CONST_PROOF_SIZE
        Fr[CONST_PROOF_SIZE_LOG_N] memory powers_of_evaluation_challenge = computeSquares(tp.geminiR);

        // Arrays hold values that will be linearly combined for the gemini and shplonk batch openings
        Fr[NUMBER_OF_ENTITIES + CONST_PROOF_SIZE_LOG_N + 2] memory scalars;
        Honk.G1Point[NUMBER_OF_ENTITIES + CONST_PROOF_SIZE_LOG_N + 2] memory commitments;

        Fr[CONST_PROOF_SIZE_LOG_N + 1] memory inverse_vanishing_evals =
            computeInvertedGeminiDenominators(tp, powers_of_evaluation_challenge);

        mem.unshiftedScalar = inverse_vanishing_evals[0] + (tp.shplonkNu * inverse_vanishing_evals[1]);
        mem.shiftedScalar =
            tp.geminiR.invert() * (inverse_vanishing_evals[0] - (tp.shplonkNu * inverse_vanishing_evals[1]));

        scalars[0] = Fr.wrap(1);
        commitments[0] = convertProofPoint(proof.shplonkQ);

        /* Batch multivariate opening claims, shifted and unshifted
        * The vector of scalars is populated as follows:
        * \f[
        * \left(
        * - \left(\frac{1}{z-r} + \nu \times \frac{1}{z+r}\right),
        * \ldots,
        * - \rho^{i+k-1} \times \left(\frac{1}{z-r} + \nu \times \frac{1}{z+r}\right),
        * - \rho^{i+k} \times \frac{1}{r} \times \left(\frac{1}{z-r} - \nu \times \frac{1}{z+r}\right),
        * \ldots,
        * - \rho^{k+m-1} \times \frac{1}{r} \times \left(\frac{1}{z-r} - \nu \times \frac{1}{z+r}\right)
        * \right)
        * \f]
        *
        * The following vector is concatenated to the vector of commitments:
        * \f[
        * f_0, \ldots, f_{m-1}, f_{\text{shift}, 0}, \ldots, f_{\text{shift}, k-1}
        * \f]
        *
        * Simultaneously, the evaluation of the multilinear polynomial
        * \f[
        * \sum \rho^i \cdot f_i + \sum \rho^{i+k} \cdot f_{\text{shift}, i}
        * \f]
        * at the challenge point \f$ (u_0,\ldots, u_{n-1}) \f$ is computed.
        *
        * This approach minimizes the number of iterations over the commitments to multilinear polynomials
        * and eliminates the need to store the powers of \f$ \rho \f$.
        */
        mem.batchingChallenge = Fr.wrap(1);
        mem.batchedEvaluation = Fr.wrap(0);

        for (uint256 i = 1; i <= NUMBER_UNSHIFTED; ++i) {
            scalars[i] = mem.unshiftedScalar.neg() * mem.batchingChallenge;
            mem.batchedEvaluation = mem.batchedEvaluation + (proof.sumcheckEvaluations[i - 1] * mem.batchingChallenge);
            mem.batchingChallenge = mem.batchingChallenge * tp.rho;
        }
        // g commitments are accumulated at r
        for (uint256 i = NUMBER_UNSHIFTED + 1; i <= NUMBER_OF_ENTITIES; ++i) {
            scalars[i] = mem.shiftedScalar.neg() * mem.batchingChallenge;
            mem.batchedEvaluation = mem.batchedEvaluation + (proof.sumcheckEvaluations[i - 1] * mem.batchingChallenge);
            mem.batchingChallenge = mem.batchingChallenge * tp.rho;
        }

        commitments[1] = vk.qm;
        commitments[2] = vk.qc;
        commitments[3] = vk.ql;
        commitments[4] = vk.qr;
        commitments[5] = vk.qo;
        commitments[6] = vk.q4;
        commitments[7] = vk.qArith;
        commitments[8] = vk.qDeltaRange;
        commitments[9] = vk.qElliptic;
        commitments[10] = vk.qAux;
        commitments[11] = vk.qLookup;
        commitments[12] = vk.qPoseidon2External;
        commitments[13] = vk.qPoseidon2Internal;
        commitments[14] = vk.s1;
        commitments[15] = vk.s2;
        commitments[16] = vk.s3;
        commitments[17] = vk.s4;
        commitments[18] = vk.id1;
        commitments[19] = vk.id2;
        commitments[20] = vk.id3;
        commitments[21] = vk.id4;
        commitments[22] = vk.t1;
        commitments[23] = vk.t2;
        commitments[24] = vk.t3;
        commitments[25] = vk.t4;
        commitments[26] = vk.lagrangeFirst;
        commitments[27] = vk.lagrangeLast;

        // Accumulate proof points
        commitments[28] = convertProofPoint(proof.w1);
        commitments[29] = convertProofPoint(proof.w2);
        commitments[30] = convertProofPoint(proof.w3);
        commitments[31] = convertProofPoint(proof.w4);
        commitments[32] = convertProofPoint(proof.zPerm);
        commitments[33] = convertProofPoint(proof.lookupInverses);
        commitments[34] = convertProofPoint(proof.lookupReadCounts);
        commitments[35] = convertProofPoint(proof.lookupReadTags);

        // to be Shifted
        commitments[36] = vk.t1;
        commitments[37] = vk.t2;
        commitments[38] = vk.t3;
        commitments[39] = vk.t4;
        commitments[40] = convertProofPoint(proof.w1);
        commitments[41] = convertProofPoint(proof.w2);
        commitments[42] = convertProofPoint(proof.w3);
        commitments[43] = convertProofPoint(proof.w4);
        commitments[44] = convertProofPoint(proof.zPerm);

        /* Batch gemini claims from the prover
         * place the commitments to gemini aᵢ to the vector of commitments, compute the contributions from
         * aᵢ(−r²ⁱ) for i=1, … , n−1 to the constant term accumulator, add corresponding scalars
         *
         * 1. Moves the vector
         * \f[
         * \left( \text{com}(A_1), \text{com}(A_2), \ldots, \text{com}(A_{n-1}) \right)
         * \f]
        * to the 'commitments' vector.
        *
        * 2. Computes the scalars:
        * \f[
        * \frac{\nu^{2}}{z + r^2}, \frac{\nu^3}{z + r^4}, \ldots, \frac{\nu^{n-1}}{z + r^{2^{n-1}}}
        * \f]
        * and places them into the 'scalars' vector.
        *
        * 3. Accumulates the summands of the constant term:
         * \f[
         * \sum_{i=2}^{n-1} \frac{\nu^{i} \cdot A_i(-r^{2^i})}{z + r^{2^i}}
         * \f]
         * and adds them to the 'constant_term_accumulator'.
         */
        mem.constantTermAccumulator = Fr.wrap(0);
        mem.batchingChallenge = tp.shplonkNu.sqr();

        for (uint256 i; i < CONST_PROOF_SIZE_LOG_N - 1; ++i) {
            bool dummy_round = i >= (LOG_N - 1);

            Fr scalingFactor = Fr.wrap(0);
            if (!dummy_round) {
                scalingFactor = mem.batchingChallenge * inverse_vanishing_evals[i + 2];
                scalars[NUMBER_OF_ENTITIES + 1 + i] = scalingFactor.neg();
            }

            mem.constantTermAccumulator =
                mem.constantTermAccumulator + (scalingFactor * proof.geminiAEvaluations[i + 1]);
            mem.batchingChallenge = mem.batchingChallenge * tp.shplonkNu;

            commitments[NUMBER_OF_ENTITIES + 1 + i] = convertProofPoint(proof.geminiFoldComms[i]);
        }

        // Add contributions from A₀(r) and A₀(-r) to constant_term_accumulator:
        // Compute evaluation A₀(r)
        Fr a_0_pos = computeGeminiBatchedUnivariateEvaluation(
            tp, mem.batchedEvaluation, proof.geminiAEvaluations, powers_of_evaluation_challenge
        );

        mem.constantTermAccumulator = mem.constantTermAccumulator + (a_0_pos * inverse_vanishing_evals[0]);
        mem.constantTermAccumulator =
            mem.constantTermAccumulator + (proof.geminiAEvaluations[0] * tp.shplonkNu * inverse_vanishing_evals[1]);

        // Finalise the batch opening claim
        commitments[NUMBER_OF_ENTITIES + CONST_PROOF_SIZE_LOG_N] = Honk.G1Point({x: 1, y: 2});
        scalars[NUMBER_OF_ENTITIES + CONST_PROOF_SIZE_LOG_N] = mem.constantTermAccumulator;

        Honk.G1Point memory quotient_commitment = convertProofPoint(proof.kzgQuotient);

        commitments[NUMBER_OF_ENTITIES + CONST_PROOF_SIZE_LOG_N + 1] = quotient_commitment;
        scalars[NUMBER_OF_ENTITIES + CONST_PROOF_SIZE_LOG_N + 1] = tp.shplonkZ; // evaluation challenge

        Honk.G1Point memory P_0 = batchMul(commitments, scalars);
        Honk.G1Point memory P_1 = negateInplace(quotient_commitment);

        return pairing(P_0, P_1);
    }

    function computeSquares(Fr r) internal pure returns (Fr[CONST_PROOF_SIZE_LOG_N] memory squares) {
        squares[0] = r;
        for (uint256 i = 1; i < CONST_PROOF_SIZE_LOG_N; ++i) {
            squares[i] = squares[i - 1].sqr();
        }
    }

    function computeInvertedGeminiDenominators(
        Transcript memory tp,
        Fr[CONST_PROOF_SIZE_LOG_N] memory eval_challenge_powers
    ) internal view returns (Fr[CONST_PROOF_SIZE_LOG_N + 1] memory inverse_vanishing_evals) {
        Fr eval_challenge = tp.shplonkZ;
        inverse_vanishing_evals[0] = (eval_challenge - eval_challenge_powers[0]).invert();

        for (uint256 i = 0; i < CONST_PROOF_SIZE_LOG_N; ++i) {
            Fr round_inverted_denominator = Fr.wrap(0);
            if (i <= LOG_N + 1) {
                round_inverted_denominator = (eval_challenge + eval_challenge_powers[i]).invert();
            }
            inverse_vanishing_evals[i + 1] = round_inverted_denominator;
        }
    }

    function computeGeminiBatchedUnivariateEvaluation(
        Transcript memory tp,
        Fr batchedEvalAccumulator,
        Fr[CONST_PROOF_SIZE_LOG_N] memory geminiEvaluations,
        Fr[CONST_PROOF_SIZE_LOG_N] memory geminiEvalChallengePowers
    ) internal view returns (Fr a_0_pos) {
        for (uint256 i = CONST_PROOF_SIZE_LOG_N; i > 0; --i) {
            Fr challengePower = geminiEvalChallengePowers[i - 1];
            Fr u = tp.sumCheckUChallenges[i - 1];
            Fr evalNeg = geminiEvaluations[i - 1];

            Fr batchedEvalRoundAcc = (
                (challengePower * batchedEvalAccumulator * Fr.wrap(2))
                    - evalNeg * (challengePower * (Fr.wrap(1) - u) - u)
            );
            // Divide by the denominator
            batchedEvalRoundAcc = batchedEvalRoundAcc * (challengePower * (Fr.wrap(1) - u) + u).invert();

            bool is_dummy_round = (i > LOG_N);
            if (!is_dummy_round) {
                batchedEvalAccumulator = batchedEvalRoundAcc;
            }
        }

        a_0_pos = batchedEvalAccumulator;
    }

    // This implementation is the same as above with different constants
    function batchMul(
        Honk.G1Point[NUMBER_OF_ENTITIES + CONST_PROOF_SIZE_LOG_N + 2] memory base,
        Fr[NUMBER_OF_ENTITIES + CONST_PROOF_SIZE_LOG_N + 2] memory scalars
    ) internal view returns (Honk.G1Point memory result) {
        uint256 limit = NUMBER_OF_ENTITIES + CONST_PROOF_SIZE_LOG_N + 2;
        assembly {
            let success := 0x01
            let free := mload(0x40)

            // Write the original into the accumulator
            // Load into memory for ecMUL, leave offset for eccAdd result
            // base is an array of pointers, so we have to dereference them
            mstore(add(free, 0x40), mload(mload(base)))
            mstore(add(free, 0x60), mload(add(0x20, mload(base))))
            // Add scalar
            mstore(add(free, 0x80), mload(scalars))
            success := and(success, staticcall(gas(), 7, add(free, 0x40), 0x60, free, 0x40))

            let count := 0x01
            for {} lt(count, limit) { count := add(count, 1) } {
                // Get loop offsets
                let base_base := add(base, mul(count, 0x20))
                let scalar_base := add(scalars, mul(count, 0x20))

                mstore(add(free, 0x40), mload(mload(base_base)))
                mstore(add(free, 0x60), mload(add(0x20, mload(base_base))))
                // Add scalar
                mstore(add(free, 0x80), mload(scalar_base))

                success := and(success, staticcall(gas(), 7, add(free, 0x40), 0x60, add(free, 0x40), 0x40))
                // accumulator = accumulator + accumulator_2
                success := and(success, staticcall(gas(), 6, free, 0x80, free, 0x40))
            }

            // Return the result - i hate this
            mstore(result, mload(free))
            mstore(add(result, 0x20), mload(add(free, 0x20)))
        }
    }

    function pairing(Honk.G1Point memory rhs, Honk.G1Point memory lhs) internal view returns (bool) {
        bytes memory input = abi.encodePacked(
            rhs.x,
            rhs.y,
            // Fixed G1 point
            uint256(0x198e9393920d483a7260bfb731fb5d25f1aa493335a9e71297e485b7aef312c2),
            uint256(0x1800deef121f1e76426a00665e5c4479674322d4f75edadd46debd5cd992f6ed),
            uint256(0x090689d0585ff075ec9e99ad690c3395bc4b313370b38ef355acdadcd122975b),
            uint256(0x12c85ea5db8c6deb4aab71808dcb408fe3d1e7690c43d37b4ce6cc0166fa7daa),
            lhs.x,
            lhs.y,
            // G1 point from VK
            uint256(0x260e01b251f6f1c7e7ff4e580791dee8ea51d87a358e038b4efe30fac09383c1),
            uint256(0x0118c4d5b837bcc2bc89b5b398b5974e9f5944073b32078b7e231fec938883b0),
            uint256(0x04fc6369f7110fe3d25156c1bb9a72859cf2a04641f99ba4ee413c80da6a5fe4),
            uint256(0x22febda3c0c0632a56475b4214e5615e11e6dd3f96e6cea2854a87d4dacc5e55)
        );

        (bool success, bytes memory result) = address(0x08).staticcall(input);
        bool decodedResult = abi.decode(result, (bool));
        return success && decodedResult;
    }
}

// Conversion util - Duplicated as we cannot template LOG_N
function convertPoints(Honk.G1ProofPoint[LOG_N + 1] memory commitments)
    pure
    returns (Honk.G1Point[LOG_N + 1] memory converted)
{
    for (uint256 i; i < LOG_N + 1; ++i) {
        converted[i] = convertProofPoint(commitments[i]);
    }
}

