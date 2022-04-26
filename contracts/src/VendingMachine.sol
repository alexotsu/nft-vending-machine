pragma solidity 0.8.13;

/**
@dev still to easy to game - using the `onERC721Received` for example, another contract could pretty easily imitate the responses needed to get past the `require` statements
Even if users were required to approve + transfer, someone could create a dummy ERC-721 that has the `transfer` method but doesn't actually send tokens
There needs to be some way to ensure that actual tokens are being transferred. Some ideas are:
  * Whitelist for addresses
  * Connect to some price oracle, and only NFTs w/ >liquidity requirements are allowed
  * Attach a cost to redeeming an NFT
 */

import "@openzeppelin/contracts/interfaces/IERC721Receiver.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/interfaces/IERC721.sol";

contract VendingMachine is IERC721Receiver, ReentrancyGuard {
  
  struct NFTRef {
    address tokenAddress;
    uint256 tokenId;
  }

  uint256 private nextInventorySlot;
  mapping(uint256 => NFTRef) public inventory;
  // @dev true if this contract already has an NFT from collection at `address`
  mapping(address => bool) private collectionOccupied;
  // @dev false = none deposited, true = 1 deposited. Since it resets to zero after depositing an NFT after 1, don't need any more values
  mapping(address => bool) private nftsDeposited;

  function onERC721Received(address operator, address from, uint256 tokenId, bytes calldata data) external override nonReentrant returns(bytes4) {
    // according to ERC721 standard, the check for if receiving contract is a receiver happens AFTER the transfer call, so this can be used to reliably see if (honest) ERC-721 contracts have done the transfer.
    require(IERC721(msg.sender).ownerOf(tokenId) == address(this), "Error: The token has not been sent yet");

    // check that a token from that collection hasn't been deposited yet
    require(!collectionOccupied[msg.sender], "Error: NFT collection already represented");

    // if false, we know the user has not deposited any NFTs. Else if true, we know there has been one deposited
    if(!nftsDeposited[from]) {
      collectionOccupied[msg.sender] = true;
      nftsDeposited[from] = true;
      inventory[nextInventorySlot] = NFTRef(msg.sender, tokenId);
      nextInventorySlot += 1;
    } else {
      nftsDeposited[from] = false;
      // where the "randomness" happens
      uint256 selectedNFTSlot = uint256(keccak256(abi.encode(block.timestamp))) % (nextInventorySlot - 1);
      IERC721(inventory[selectedNFTSlot].tokenAddress).safeTransferFrom(address(this), from, inventory[selectedNFTSlot].tokenId);
      collectionOccupied[inventory[selectedNFTSlot].tokenAddress] = false;
      inventory[selectedNFTSlot] = NFTRef(msg.sender, tokenId);
      collectionOccupied[msg.sender] = true;
    }

    return this.onERC721Received.selector;
  }
}