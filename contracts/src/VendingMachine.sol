pragma solidity 0.8.13;

import "contracts/lib/openzeppelin-contracts/contracts/interfaces/IERC721Receiver.sol";
import "contracts/lib/openzeppelin-contracts/contracts/security/ReentrancyGuard.sol";
import "contracts/lib/openzeppelin-contracts/contracts/interfaces/IERC721.sol";

contract VendingMachine is IERC721Receiver, ReentrancyGuard {
  // Receiving: two ways to the user to send
    // 1. Call `transferApprovedNFTs(address addr1, uint tokenId1, address addr2, uint tokenId2)` to transfer approved NFTs from user to contract
    // 2. Just send NFTs. Is this even reliable, as an outside contract could just as easily call this function?
      // test if checking for `ownerOf` works - According to ERC721 standard, checking if it is a receiver is done AFTER the transfer call. Shouldn't be able to spoof `msg.sender` being the original contract.
    // All validation logic will be handled in `onERC721Received`
      // When they send their first NFT, it is added to the `inventory` value at `nextInventorySlot`
      // Whenever they send their second NFT, `claim` is automatically triggered
  
  // Gacha-ing
    // Checks: user has 2 NFTs
    // Effects: 
      // Reset NFTs deposited count to 0
      // Calculate the token they will receive based on the pre-deposit state of `inventory`
    // Interactions:
      // Transfer NFT to user
      // replace the NFT at the `inventory` mapping slot with their NFT that triggered `claim`
  
  struct NFTRef {
    address tokenAddress;
    uint256 tokenId;
  }

  uint256 private nextInventorySlot;
  mapping(uint256 => NFTRef) public inventory;
  // @dev true if NFT from collection at `address` has already been
  mapping(address => bool) private collectionOccupied;
  // false = none deposited, true = 1 deposited. Since it resets to zero after depositing an NFT after 1, don't need any more values
  mapping(address => bool) private nftsDeposited;

  function onERC721Received(operator, from, tokenId, data) external override {
    // checks that the token has actually been sent (msg.sender should always be the original ERC-721)
    require(IERC721(msg.sender).ownerOf(tokenId) == this.address, "The token has not been sent yet");

    // check that a token from that collection hasn't been deposited yet
    // needs "NFT collection represented" error
    require(!collectionOccupied[msg.sender], "Error: NFT collection already represented");

    // check that this wouldn't put the NFT holder's NFT count above 2
    // needs "User has already deposited 2 NFTs" error
    // require(nftsDeposited[from] < 2, "Error: User has deposited 2 NFTs");

    // first NFT
    if(!nftsDeposited[from]) {
      // add collection to collectionOccupied
      // add to user's collection
      // add to inventory (increment counter, add)
      collectionOccupied[msg.sender] = true;
      nftsDeposited[from] = true;
      inventory[nextInventorySlot] = NFTRef(msg.sender, tokenId);
      nextInventorySlot += 1;
    } else {
      // else if true, we know there has been one deposited
      nftsDeposited[from] = false;
      uint256 selectedNFTSlot = uint256(keccak256(block.timestamp)) % (nextInventorySlot - 1);
      IERC721(inventory[selectedNFTSlot].tokenAddress).safeTransferFrom(address(this), from, inventory[selectedNFTSlot].tokenId);
      collectionOccupied[inventory[selectedNFTSlot].tokenAddress] = false;
      inventory[selectedNFTSlot] = NFTRef(msg.sender, tokenId);
      collectionOccupied[msg.sender] = true;
    }

    return this.onERC721Received.selector;
  }
}