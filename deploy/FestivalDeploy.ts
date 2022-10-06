import { run } from 'hardhat';
import { DeployFunction } from 'hardhat-deploy/types';

const migrate: DeployFunction = async ({ getNamedAccounts, deployments: { deploy }, config, network }) => {
  const { deployer } = await getNamedAccounts();
  if (!deployer) {
    console.error(
      '\n\nERROR!\n\nThe node you are deploying to does not have access to a private key to sign this transaction. Add a Private Key in this application to solve this.\n\n'
    );
    process.exit(1);
  }

  const festivalToken = await deploy('FestivalToken', {
    from: deployer,
    args: [
      'FestivalToken',
      'FTK'
    ],
    log: true,
  });

  await deploy('FestivalNFT', {
    from: deployer,
    args: [
      'FestivalNFT',
      'FNFT',
      'https://gateway-festivalstorage-eafc.settlemint.com/ipfs/QmUczjxs9UYvSjufENGV9qzw17Spo3o4EVFDQKSm3U9b1C?filename=SETTLEMINT_TEST.jpg',
      festivalToken.address
    ],
    log: true,
  });

  let hasEtherScanInstance = false;
  try {
    await run('verify:get-etherscan-endpoint');
    hasEtherScanInstance = true;
  } catch (e) {
    // ignore
  }
  if (hasEtherScanInstance) {
    await run('sourcify');
    if (!config.verify?.etherscan?.apiKey) {
      console.error(
        `\n\nERROR!\n\nYou have not set your Etherscan API key in your hardhat.config.ts file. Set it and run\n\nyarn hardhat --network '${network.name}' etherscan-verify\n\n`
      );
    } else {
      await new Promise((resolve) => {
        setTimeout(resolve, 10 * 1000);
      }); // allow etherscan to catch up
      await run('etherscan-verify');
    }
  }

  return true;
};

export default migrate;

migrate.id = '00_deploy_example';
migrate.tags = ['Example'];
