const CrowdSale = artifacts.require("CrowdSale");

module.exports = async function (deployer) {
  await deployer.deploy(
    CrowdSale,
    "0xf886abace837e5ec0cf7037b4d2198f7a1bf35b5",
    "137760020000000",
    "0xe152B27c45CFA649649AACA395922C58273A6DEe"
  );
};
