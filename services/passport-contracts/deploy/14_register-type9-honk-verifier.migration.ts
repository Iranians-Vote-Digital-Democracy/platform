import { Deployer, Reporter } from "@solarity/hardhat-migrate";
import { AbiCoder, solidityPackedKeccak256 as keccak256 } from "ethers";

import {
  NoirRegisterIdentity_ID_Card_I_Honk__factory,
  NoirRegisterIdentity_9_160_3_3_336_216_1_1080_3_256_Honk__factory,
  Registration2__factory,
} from "@ethers-v6";

const Z_NOIR_PASSPORT_9_160_3_3_336_216_1_1080_3_256 = keccak256(
  ["string"],
  ["Z_NOIR_PASSPORT_9_160_3_3_336_216_1_1080_3_256"],
);

const Z_NOIR_PASSPORT_ID_CARD_I = keccak256(
  ["string"],
  ["Z_NOIR_PASSPORT_ID_CARD_I"],
);

export = async (deployer: Deployer) => {
  const registration = await deployer.deployed(Registration2__factory, "Registration2 Proxy");

  // Deploy Type 9 passport Honk verifier
  const type9HonkVerifier = await deployer.deploy(NoirRegisterIdentity_9_160_3_3_336_216_1_1080_3_256_Honk__factory);

  // Deploy INID Honk verifier (generated from registerIdentity_inid_ca circuit)
  const inidHonkVerifier = await deployer.deploy(NoirRegisterIdentity_ID_Card_I_Honk__factory);

  // Register Type 9 Honk verifier
  await registration.updateDependency(
    5,
    AbiCoder.defaultAbiCoder().encode(
      ["bytes32", "address"],
      [Z_NOIR_PASSPORT_9_160_3_3_336_216_1_1080_3_256, await type9HonkVerifier.getAddress()],
    ),
  );

  // Remove old INID Plonk verifier (methodId 6 = RemovePassportVerifier)
  await registration.updateDependency(
    6,
    AbiCoder.defaultAbiCoder().encode(
      ["bytes32"],
      [Z_NOIR_PASSPORT_ID_CARD_I],
    ),
  );

  // Register INID Honk verifier (methodId 5 = AddPassportVerifier)
  await registration.updateDependency(
    5,
    AbiCoder.defaultAbiCoder().encode(
      ["bytes32", "address"],
      [Z_NOIR_PASSPORT_ID_CARD_I, await inidHonkVerifier.getAddress()],
    ),
  );

  Reporter.reportContracts([
    "NoirRegisterIdentity_9_160_3_3_336_216_1_1080_3_256_Honk",
    `${await type9HonkVerifier.getAddress()}`,
    "NoirRegisterIdentity_ID_Card_I_Honk",
    `${await inidHonkVerifier.getAddress()}`,
  ]);
};