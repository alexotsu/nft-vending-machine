# nft-vending-machine

A toy contract I made where you can send two NFTs in and get a random other one out. Utilizes the `onERC721Received` hook to update internal accounting.

Only problem is it's very easy to spoof by creating a contract that just sends the right values to pass the `require` checks.

Potential mitigants to ensure the transfers are coming from legit NFT addresses include:
1. Querying an oracle to check for some volume/price threshold of incoming tokens
2. Whitelist certain contract addresses
3. Impose a fee on depositing an NFT for some sybil resistance

All this is to say, do not use this anywhere near a production environment. It was mostly made as a learning tool to get familiar with Forge and think about adversarial scenarios.