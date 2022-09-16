import { HardhatUserConfig } from 'hardhat/config';
import bpaasConfig from './.secrets/default.hardhat.config';
import './tasks/library/graph-config';
import './tasks/library/ipfs-cid';
import './tasks/library/ipfs-upload-file';
import './tasks/library/opensea-proxy-address';
import './tasks/library/whitelist';

const config: HardhatUserConfig = {
  ...bpaasConfig,
};

// If you want to pin your NFT assets, add a token here from https://nft.storage
export const nftStorageToken = '';

export default config;
