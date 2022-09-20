import { loadFixture } from '@nomicfoundation/hardhat-network-helpers';
import { expect } from 'chai';
import { ethers } from 'hardhat';
describe('Festival', function () {
  // We define a fixture to reuse the same setup in every test.
  // We use loadFixture to run this setup once, snapshot that state,
  // and reset Hardhat Network to that snapshot in every test.
  async function deployLockFixture() {
    // Contracts are deployed using the first signer/account by default
    const [ organiser, buyer1, buyer2, buyer3] = await ethers.getSigners();

    // Deploying Festival Token
    const FestivalToken = await ethers.getContractFactory('FestivalToken');
    const festivalToken = await FestivalToken.deploy('FestivalToken', 'FTK');

    // Deploying Festival NFT
    const FestivalNFT = await ethers.getContractFactory('FestivalNFT');
    const festivalNFT = await FestivalNFT.deploy('FestivalNFT', 'FNFT', 'Link to NFT image', festivalToken.address);

    return { organiser, buyer1, buyer2, buyer3, festivalToken, festivalNFT };
  }

  describe('Check Initialisation', function () {
    it('FTK should be initialised', async function () {
      const { festivalToken } = await loadFixture(deployLockFixture);

      expect(await festivalToken.totalSupply()).to.equal(
        ethers.utils.parseUnits('1', 24) // 1 million FTK * 18 decimals
      );
    });

    it('FNFT should be initialised', async function () {
      const { organiser, festivalNFT } = await loadFixture(deployLockFixture);

      expect(await festivalNFT.wallet()).to.equal(organiser.address);
    });
  });

  describe('Check Minting of FTK', function () {
    it('Minting of tokens from organiser to buyers', async function () {
      const { buyer1, buyer2, buyer3, festivalToken } = await loadFixture(deployLockFixture);

      await festivalToken.mint(buyer1.address, ethers.utils.parseUnits('1', 20)); // minting 100 FTK
      await festivalToken.mint(buyer2.address, ethers.utils.parseUnits('1', 20)); // minting 100 FTK
      await festivalToken.mint(buyer3.address, ethers.utils.parseUnits('1', 20)); // minting 100 FTK

      expect(await festivalToken.totalSupply()).to.equal(
        ethers.utils.parseUnits('1000300', 18) // (1 million + 300) FTK * 18 decimals
      );

      expect(await festivalToken.balanceOf(buyer1.address)).to.equal(
        ethers.utils.parseUnits('100', 18) // 100 FTK * 18 decimals
      );

      expect(await festivalToken.balanceOf(buyer2.address)).to.equal(
        ethers.utils.parseUnits('100', 18) // 100 FTK * 18 decimals
      );

      expect(await festivalToken.balanceOf(buyer3.address)).to.equal(
        ethers.utils.parseUnits('100', 18) // 100 FTK * 18 decimals
      );
    });
  });

  describe('Check Public Minting of FNFT', function () {
    it('Successful minting of 1 FNFT', async function () {
      const {  buyer1, festivalToken, festivalNFT } = await loadFixture(deployLockFixture);

      await festivalToken.mint(buyer1.address, ethers.utils.parseUnits('1', 20)); // minting 100 FTK

      // Initialising public sale
      await festivalNFT.startPublicSale();

      // Approving buyer1 to transact in FTK
      await festivalToken.connect(buyer1).approve(festivalNFT.address, festivalToken.totalSupply());

      // Minting 1 FNFT at 10 FTK
      await festivalNFT.connect(buyer1).publicMint(1);

      // Checking FTK balance of buyer1
      expect(await festivalToken.balanceOf(buyer1.address)).to.equal(
        ethers.utils.parseUnits('90', 18) // 90 FTK * 18 decimals
      );

      // Checking FNFT balance of buyer1
      expect(await festivalNFT.balanceOf(buyer1.address)).to.equal(
        1 // 1 FNFT
      );
    });

    it('Successful minting of 5 FNFTs [limit]', async function () {
      const { buyer1, festivalToken, festivalNFT } = await loadFixture(deployLockFixture);

      await festivalToken.mint(buyer1.address, ethers.utils.parseUnits('1', 20)); // minting 100 FTK

      // Initialising public sale
      await festivalNFT.startPublicSale();

      // Approving buyer1 to transact in FTK
      await festivalToken.connect(buyer1).approve(festivalNFT.address, festivalToken.totalSupply());

      await festivalNFT.connect(buyer1).publicMint(5);

      // Checking FTK balance of buyer1
      expect(await festivalToken.balanceOf(buyer1.address)).to.equal(
        ethers.utils.parseUnits('50', 18) // 50 FTK * 18 decimals
      );

      // Checking FNFT balance of buyer1
      expect(await festivalNFT.balanceOf(buyer1.address)).to.equal(
        5 // 5 FNFT
      );
    });

    it('Exceeds max per transaction : 6 FNFTs [Exceed]', async function () {
      const { buyer1, festivalToken, festivalNFT } = await loadFixture(deployLockFixture);

      await festivalToken.mint(buyer1.address, ethers.utils.parseUnits('1', 20)); // minting 100 FTK

      // Initialising public sale
      await festivalNFT.startPublicSale();

      // Approving buyer1 to transact in FTK
      await festivalToken.connect(buyer1).approve(festivalNFT.address, festivalToken.totalSupply());

      await expect(festivalNFT.connect(buyer1).publicMint(6)).to.be.revertedWith('Exceeds max per transaction');
    });

    it('Exceeds maximum public minting : 2 sets of 3 FNFTs [Exceed]', async function () {
      const { buyer1, festivalToken, festivalNFT } = await loadFixture(deployLockFixture);

      await festivalToken.mint(buyer1.address, ethers.utils.parseUnits('1', 20)); // minting 100 FTK

      // Initialising public sale
      await festivalNFT.startPublicSale();

      // Approving buyer1 to transact in FTK
      await festivalToken.connect(buyer1).approve(festivalNFT.address, festivalToken.totalSupply());

      await festivalNFT.connect(buyer1).publicMint(3);
      await expect(festivalNFT.connect(buyer1).publicMint(3)).to.be.revertedWith('Exceeds maximum public minting');
    });
  });

  describe('Check Listing of FNFT on Secondary Marketplace', function () {
    it('Successful listing of 1 FNFT', async function () {
      const {organiser, buyer1, festivalToken, festivalNFT } = await loadFixture(deployLockFixture);

      await festivalToken.mint(buyer1.address, ethers.utils.parseUnits('1', 20)); // minting 100 FTK

      // Initialising public sale
      await festivalNFT.startPublicSale();

      // Approving buyer1 to transact in FTK
      await festivalToken.connect(buyer1).approve(festivalNFT.address, festivalToken.totalSupply());

      // Minting 1 FNFT at 10 FTK
      await festivalNFT.connect(buyer1).publicMint(1);

      // Approving organiser to transfer FNFT
      await festivalNFT.connect(buyer1).approve(organiser.address,1);

      // Listing 1 FNFT at 11 FTK
      await festivalNFT.connect(buyer1).setListing(1, ethers.utils.parseUnits('11', 18));

      expect(await festivalNFT.getSellingPrice(1)).to.equal(
        ethers.utils.parseUnits('11', 18) // 11 FTK * 18 decimals
      );
    });

    it('Failure listing of 1 FNFT above 110% Threshold', async function () {
      const { organiser, buyer1,  festivalToken, festivalNFT } = await loadFixture(deployLockFixture);

      await festivalToken.mint(buyer1.address, ethers.utils.parseUnits('1', 20)); // minting 100 FTK

      // Initialising public sale
      await festivalNFT.startPublicSale();

      // Approving buyer1 to transact in FTK
      await festivalToken.connect(buyer1).approve(festivalNFT.address, festivalToken.totalSupply());

      // Minting 1 FNFT at 10 FTK
      await festivalNFT.connect(buyer1).publicMint(1);

      // Approving organiser to transfer FNFT
      await festivalNFT.connect(buyer1).approve(organiser.address,1);

      // Listing 1 FNFT at 12 FTK
      await expect(festivalNFT.connect(buyer1).setListing(1, ethers.utils.parseUnits('12', 18))).to.be.revertedWith(
        'Re-selling price is more than 110%'
      );
    });

    it('Successful purchase listing of 1 FNFT ', async function () {
      const { organiser, buyer1, buyer2, festivalToken, festivalNFT } = await loadFixture(deployLockFixture);

      await festivalToken.mint(buyer1.address, ethers.utils.parseUnits('1', 20)); // minting 100 FTK
      await festivalToken.mint(buyer2.address, ethers.utils.parseUnits('1', 20)); // minting 100 FTK

      // Initialising public sale
      await festivalNFT.startPublicSale();

      // Approving buyer1 and buyer2 to transact in FTK
      await festivalToken.connect(buyer1).approve(festivalNFT.address, festivalToken.totalSupply());
      await festivalToken.connect(buyer2).approve(festivalNFT.address, festivalToken.totalSupply());

      // Minting 1 FNFT at 10 FTK
      await festivalNFT.connect(buyer1).publicMint(1);

      // Approving organiser to transfer FNFT
      await festivalNFT.connect(buyer1).approve(organiser.address,1);

      // Listing 1 FNFT at 11 FTK
      await festivalNFT.connect(buyer1).setListing(1, ethers.utils.parseUnits('11', 18));

      // Approving buyer2 to purchase
      await festivalNFT.approve(buyer2.address,1)

      // Purchasing of 1 FNFT at 11 FTK
      await festivalNFT.connect(buyer2).purchaseListing(1, ethers.utils.parseUnits('11', 18));

      expect(await festivalNFT.balanceOf(buyer1.address)).to.equal(0);
      expect(await festivalNFT.balanceOf(buyer2.address)).to.equal(1);
    });
  });

  describe('Check Monetisation', function () {
    it('Successful monetisation - 10%', async function () {
      const {  buyer1, buyer2, festivalToken, festivalNFT } = await loadFixture(deployLockFixture);

      await festivalToken.mint(buyer1.address, ethers.utils.parseUnits('1', 20)); // minting 100 FTK
      await festivalToken.mint(buyer2.address, ethers.utils.parseUnits('1', 20)); // minting 100 FTK

      // Initialising public sale
      await festivalNFT.startPublicSale();
      await festivalNFT.monetise(10);

      // Approving buyer1 and buyer2 to transact in FTK
      await festivalToken.connect(buyer1).approve(festivalNFT.address, festivalToken.totalSupply());
      await festivalToken.connect(buyer2).approve(festivalNFT.address, festivalToken.totalSupply());

      // Minting 1 FNFT at 10 FTK
      await festivalNFT.connect(buyer1).publicMint(1);

      // Approving organiser to transfer FNFT
      await festivalNFT.connect(buyer1).approve(organiser.address,1);

      // Listing 1 FNFT at 11 FTK
      await festivalNFT.connect(buyer1).setListing(1, ethers.utils.parseUnits('10', 18));

      // Approving buyer2 to purchase
      await festivalNFT.approve(buyer2.address,1)

      // Purchasing of 1 FNFT at 10 FTK
      await festivalNFT.connect(buyer2).purchaseListing(1, ethers.utils.parseUnits('10', 18));

      // Checking FTK balance of buyer1, should be 10% less of 10, note need to deduct the price of public mint
      expect(await festivalToken.balanceOf(buyer1.address)).to.equal(
        ethers.utils.parseUnits('99', 18)
      );

      // Checking FTK balance of buyer2
      expect(await festivalToken.balanceOf(buyer2.address)).to.equal(
        ethers.utils.parseUnits('90', 18)
      );
    });
  });
});
