# Foundry Fund Me

## Getting Started

### Requirements

- **git**  
  You'll know it's installed if you can run:
  ```bash
  git --version
  ```
  and get something like:
  ```
  git version x.x.x
  ```

- **foundry**  
  You'll know it's installed if you can run:
  ```bash
  forge --version
  ```
  and see something like:
  ```
  forge 0.2.0 (816e00b 2023-03-16T00:05:26.396218Z)
  ```

## Quickstart

```bash
git clone https://github.com/billKaunda/fund-me

cd fund-me
make
```

## Optional: Gitpod

If you can’t or don’t want to run and install locally, you can work with this repo in Gitpod.

> If using Gitpod, you can skip the `git clone` step.

[Open in Gitpod](https://gitpod.io/#https://github.com/billKaunda/fund-me)

---

## Usage

### Deploy

```bash
forge script script/DeployFundMe.s.sol
```

---

## Testing

We implement about 3 test tiers in the project. The last one staging is not integrated:

1. Unit  
2. Integration  
3. Forked  
4. Staging  


```bash
forge test
```

Run a specific test function:

> **Note**:  
> `"forge test -m testFunctionName"` is deprecated.  
> Use the new format:

```bash
forge test --match-test testFunctionName
```

Or test using a fork:

```bash
forge test --fork-url $SEPOLIA_RPC_URL
```

---

## Test Coverage

```bash
forge coverage
```

---

## Local zkSync

The instructions below help you work with this repo using zkSync.

### Additional Requirements

In addition to earlier tools, you'll need:

- **foundry-zksync**  
  Confirm installation with:
  ```bash
  forge --version
  ```
  Expect output like:
  ```
  forge 0.0.2 (816e00b 2023-03-16T00:05:26.396218Z)
  ```

- **npm & npx**
  ```bash
  npm --version
  npx --version
  ```

- **Docker**  
  Check if installed:
  ```bash
  docker --version
  ```
  Output example:
  ```
  Docker version 20.10.7, build f0df350
  ```

  Ensure the Docker daemon is running:
  ```bash
  docker info
  ```

  Look for:
  ```
  Client:
   Context:    default
   Debug Mode: false
  ```

---

### Setup Local zkSync Node

Run:

```bash
npx zksync-cli dev config
```

Select:
- In-memory node
- No additional modules

Start the node:

```bash
npx zksync-cli dev start
```

Expected output:

```
In memory node started v0.1.0-alpha.22:
 - zkSync Node (L2):
  - Chain ID: 260
  - RPC URL: http://127.0.0.1:8011
  - Rich accounts: https://era.zksync.io/docs/tools/testing/era-test-node.html#use-pre-configured-rich-wallets
```

---

### Deploy to Local zkSync Node

```bash
make deploy-zk
```

This deploys:
- A mock price feed
- The FundMe contract

---

## Deployment to a Testnet or Mainnet

### Setup Environment Variables

Create a `.env` file (or export manually) with:

- `SEPOLIA_RPC_URL`: Sepolia testnet RPC URL (e.g., from Alchemy)
- `PRIVATE_KEY`: Your wallet private key  
  ⚠️ **Only use a dev/test wallet.**

Optionally:

- `ETHERSCAN_API_KEY`: For contract verification on Etherscan

---

### Get Testnet ETH

Use [faucets.chain.link](https://faucets.chain.link/) to get test ETH. Check MetaMask to confirm it arrived.

---

### Deploy

```bash
forge script script/DeployFundMe.s.sol \
  --rpc-url $SEPOLIA_RPC_URL \
  --account $ENCRYPTED_KEYSTORE_ACCOUNT \
  --broadcast \
  --verify \
  --etherscan-api-key $ETHERSCAN_API_KEY
```

---

## Scripts

Interact with your deployed contracts.

### Fund Locally Using `cast`

```bash
cast send <FUNDME_CONTRACT_ADDRESS> "fund()" \
  --value 0.1ether \
  --account $ENCRYPTED_KEYSTORE_ACCOUNT 
```

### Fund via `forge`

```bash
forge script script/Interactions.s.sol:FundFundMe \
  --rpc-url sepolia \
  --account $ENCRYPTED_KEYSTORE_ACCOUNT \
  --broadcast
```

### Withdraw via `forge`

```bash
forge script script/Interactions.s.sol:WithdrawFundMe \
  --rpc-url sepolia \
  --account $ENCRYPTED_KEYSTORE_ACCOUNT \
  --broadcast
```

---

## Withdraw with `cast`

```bash
cast send <FUNDME_CONTRACT_ADDRESS> "withdraw()" \
  --account $ENCRYPTED_KEYSTORE_ACCOUNT 
```

---

## Estimate Gas

```bash
forge snapshot
```

This generates a `.gas-snapshot` file.

---

## Formatting

To automatically format your code:

```bash
forge fmt
```

---

## Additional Info

Some users were unsure if [`chainlink-brownie-contracts`](https://github.com/smartcontractkit/chainlink-brownie-contracts) is official.

✅ **Yes, it's official.**

- Owned and maintained by the Chainlink team
- Follows the official release cycle
- Uses the `smartcontractkit` GitHub org

### What does “official” mean?

Chainlink publishes releases to **npm**, which is their official distribution method. So:

- ✅ Use `npm` packages directly
- ✅ Or use `chainlink-brownie-contracts` which wraps the npm packages nicely for Foundry

Both are valid — pick the one that fits your workflow.

---
