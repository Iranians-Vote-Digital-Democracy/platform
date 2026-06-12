import { Deployer, Reporter } from "@solarity/hardhat-migrate";
import { AbiCoder, solidityPackedKeccak256 as keccak256 } from "ethers";

import {
  NoirRegisterIdentity_ID_Card_I_Honk__factory,
  Registration2__factory,
} from "@ethers-v6";

const Z_NOIR_PASSPORT_9_160_3_3_336_216_1_1080_3_256 = keccak256(
  ["string"],
  ["Z_NOIR_PASSPORT_9_160_3_3_336_216_1_1080_3_256"],
);

export = async (deployer: Deployer) => {
  const registration = await deployer.deployed(Registration2__factory, "Registration2 Proxy");
  const type9HonkVerifier = await deployer.deploy(NoirRegisterIdentity_ID_Card_I_Honk__factory);

  await registration.updateDependency(
    5,
    AbiCoder.defaultAbiCoder().encode(
      ["bytes32", "address"],
      [Z_NOIR_PASSPORT_9_160_3_3_336_216_1_1080_3_256, await type9HonkVerifier.getAddress()],
    ),
  );

  Reporter.reportContracts([
    "NoirRegisterIdentity_9_160_3_3_336_216_1_1080_3_256_Honk",
    `${await type9HonkVerifier.getAddress()}`,
  ]);
};