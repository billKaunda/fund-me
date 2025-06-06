-include .env
# This Makefile is updated as at Apr 9, 2025

# Never commit keystore files to git. Consider having them in a .gitignore # file.
KEYSTORE_PATH := $(HOME)/.foundry/keystores/
SEPOLIA_ACCOUNT := $(KEYSTORE_PATH)sepolia.json
ZKSYNC_ACCOUNT := $(KEYSTORE_PATH)zksync-sepolia-testnet.json

# Default to anvil
NETWORK_ARGS := --rpc-url http://localhost:8545 --private-key $(DEFAULT_ANVIL_KEY) --broadcast

define GET_NETWORK_ARGS
ifeq ($(findstring --chain sepolia,$(ARGS)),--chain sepolia)
	NETWORK_ARGS := --rpc-url $(SEPOLIA_RPC_URL) --account $(SEPOLIA_ACCOUNT) --broadcast --verify --verifier etherscan --etherscan-api-key $(ETHERSCAN_API_KEY) -vvvv
else ifeq ($(findstring --chain zksync,$(ARGS)),--chain zksync)
	NETWORK_ARGS := --rpc-url $(ZKSYNC_RPC_URL) --account $(ZKSYNC_ACCOUNT) --broadcast --verify --verifier zksync --etherscan-api-key $(ETHERSCAN_API_KEY) -vvvv
else ifeq ($(findstring --chain anvil,$(ARGS)),--chain anvil)
	NETWORK_ARGS := --rpc-url http://localhost:8545 --private-key $(DEFAULT_ANVIL_KEY) --broadcast
else
	$(error Please specify a valid network argument: sepolia, zksync, or anvil)
endif
endef

.PHONY: all test clean deploy fund help install snapshot format anvil zktest

all: clean remove install update build

# Clean the repo
clean  :; forge clean

# Remove modules
remove :; rm -rf .gitmodules && rm -rf .git/modules/* && rm -rf lib && touch .gitmodules && git add . && git commit -m "modules"

install :; forge install cyfrin/foundry-devops@0.3.2 && forge install smartcontractkit/chainlink-brownie-contracts@1.3.0 && forge install foundry-rs/forge-std@v1.8.2 --no-commit

# Update Dependencies
update:; forge update

build:; forge build

zkbuild :; forge build --zksync

test :; forge test

zktest :; foundryup-zksync && forge test --zksync && foundryup

snapshot :; forge snapshot

format :; forge fmt

anvil :; anvil -m 'test test test test test test test test test test test junk' --steps-tracing --block-time 1

zk-anvil :; npx zksync-cli dev start

# ==========================================================
# DEPLOY TARGETS
# ==========================================================

deploy:
	$(eval $(GET_NETWORK_ARGS))
	@forge script script/DeployFundMe.s.sol:DeployFundMe $(ARGS) $(NETWORK_ARGS)

deploy-sepolia:
	$(eval $(GET_NETWORK_ARGS))
	@forge script script/DeployFundMe.s.sol:DeployFundMe $(ARGS) $(NETWORK_ARGS)

# As of writing, the Alchemy zkSync RPC URL is not working correctly 
deploy-zk:
	forge create src/FundMe.sol:FundMe --rpc-url http://127.0.0.1:8011 --private-key $(DEFAULT_ZKSYNC_LOCAL_KEY) --constructor-args $(shell forge create lib/chainlink-brownie-contracts/contracts/src/v0.8/tests/MockV3Aggregator.sol:MockV3Aggregator --rpc-url http://127.0.0.1:8011 --private-key $(DEFAULT_ZKSYNC_LOCAL_KEY) --constructor-args 8 200000000000 --legacy --zksync | grep "Deployed to:" | awk '{print $$3}') --legacy --zksync

deploy-zk-sepolia:
	forge create src/FundMe.sol:FundMe --rpc-url ${ZKSYNC_SEPOLIA_RPC_URL} --account default --constructor-args 0xfEefF7c3fB57d18C5C6Cdd71e45D2D0b4F9377bF --legacy --zksync


# For deploying Interactions.s.sol:FundFundMe as well as for Interactions.s.sol:WithdrawFundMe we have to include a sender's address `--sender <ADDRESS>`
SENDER_ADDRESS := <sender's address>
 
fund:
	@forge script script/Interactions.s.sol:FundFundMe --sender $(SENDER_ADDRESS) $(NETWORK_ARGS)

withdraw:
	@forge script script/Interactions.s.sol:WithdrawFundMe --sender $(SENDER_ADDRESS) $(NETWORK_ARGS)