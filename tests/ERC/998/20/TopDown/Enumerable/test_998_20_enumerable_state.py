from collections import defaultdict

from brownie.network.account import Account
from brownie.network.contract import Contract, ContractContainer
from brownie.test import contract_strategy, strategy


class State:
    def __init__(self):
        # tokens[token] -> childcontracts[erc20contract] -> balance
        self.tokens = defaultdict(lambda: defaultdict(int))

    def receive_erc20(self, token_id: int, contract: str, value: int):
        """Receive some amount of an ERC20 token."""
        self.tokens[token_id][contract] += value
        assert self.tokens[token_id][contract] >= 0

    def remove_erc20(self, token_id: int, contract: str, value: int):
        """Remove some amount of an ERC20 token."""
        self.tokens[token_id][contract] -= value
        assert self.tokens[token_id][contract] >= 0

    def erc20_contracts(self, token_id: int) -> set:
        """Get all ERC20 contracts which token holds value in."""
        return {k for k, v in self.tokens[token_id].items() if v > 0}

    def total_erc20_contracts(self, token_id: int) -> int:
        """Get the total number of ERC20 contracts of a token."""
        return len(self.erc20_contracts(token_id))


class StateMachine:

    st_contract = contract_strategy("ERC20")
    st_token = strategy("uint256", max_value=9)
    st_amount = strategy("uint256", max_value=2 ** 16 * 10 ** 18)

    def __init__(cls, alice: Account, ERC20: ContractContainer, xhibit: Contract):
        cls.alice = alice
        cls.xhibit = xhibit

        # create 10 mock ERC20 contracts
        for i in range(10):
            instance = alice.deploy(ERC20, f"Test Token {i}", f"TST{i}", 18)
            # mint a s#!t ton of tokens :)
            instance._mint_for_testing(alice, 2 ** 256 - 1, {"from": alice})
            # approve ahead of time
            instance.approve(xhibit, 2 ** 256 - 1, {"from": alice})
            # create 10 xhibit NFTs as well
            xhibit.mint(alice, {"from": alice})

    def setup(self):
        self.state = State()

    def rule_receive_erc20(
        self, st_contract: Contract, st_token: int, st_amount: int,
    ):
        if st_contract.balanceOf(self.alice) >= st_amount:
            st_contract.approve(self.xhibit, 2 ** 256 - 1, {"from": self.alice})
            self.xhibit.getERC20(self.alice, st_token, st_contract, st_amount)
            self.state.receive_erc20(st_token, str(st_contract), st_amount)

    def rule_remove_erc20(self, st_contract: Contract, st_token: int, st_amount: int):
        if self.xhibit.balanceOfERC20(st_token, st_contract) >= st_amount:
            self.xhibit.transferERC20(st_token, self.alice, st_contract, st_amount)
            self.state.remove_erc20(st_token, str(st_contract), st_amount)

    def rule_clear_erc20(self, st_contract: Contract, st_token: int):
        balance = self.xhibit.balanceOfERC20(st_token, st_contract)
        if balance > 0:
            self.xhibit.transferERC20(st_token, self.alice, st_contract, balance)
            self.state.remove_erc20(st_token, str(st_contract), balance)

    def invariant_totalERC20Contracts(self):
        # for each xhibit NFT verify the total # of child contracts
        for i in range(10):
            assert self.xhibit.totalERC20Contracts(
                i
            ) == self.state.total_erc20_contracts(i)

    def invariant_erc20ContractByIndex(self):
        # for each xhibit NFT
        for i in range(10):
            erc20_contracts = {
                self.xhibit.erc20ContractByIndex(i, j)
                for j in range(self.state.total_erc20_contracts(i))
            }
            assert erc20_contracts == self.state.erc20_contracts(i)

    def invariant_erc20_balance(self):
        # for each xhibit NFT
        for i in range(10):
            erc20_contracts = {
                self.xhibit.erc20ContractByIndex(i, j)
                for j in range(self.state.total_erc20_contracts(i))
            }
            for contract in erc20_contracts:
                assert (
                    self.xhibit.balanceOfERC20(i, contract)
                    == self.state.tokens[i][contract]
                )


def test_state(alice, ERC20, state_machine, xhibit):
    state_machine(StateMachine, alice, ERC20, xhibit)
