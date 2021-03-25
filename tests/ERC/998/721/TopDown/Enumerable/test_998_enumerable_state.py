from collections import defaultdict

from brownie.network.account import Account
from brownie.network.contract import Contract, ContractContainer
from brownie.test import contract_strategy, strategy


class State:
    def __init__(self):
        # tokens[token] -> childcontracts[childcontract] -> childtokens
        self.tokens = defaultdict(lambda: defaultdict(set))

    def receive_child(self, token_id: int, child_contract: str, child_token: int):
        """Receive a child token."""
        self.tokens[token_id][child_contract].add(child_token)

    def remove_child(self, token_id: int, child_contract: str, child_token: int):
        """Remove a child token."""
        self.tokens[token_id][child_contract].remove(child_token)

    def child_contracts(self, token_id: int) -> set:
        """Get all child contracts of a token."""
        return {k for k, v in self.tokens[token_id].items() if len(v) > 0}

    def total_child_contracts(self, token_id: int) -> int:
        """Get the total number of child contracts of a token."""
        return len(self.child_contracts(token_id))

    def child_tokens(self, token_id: int, child_contract: str) -> set:
        """Get all the child tokens held by a token from a specific contract."""
        return self.tokens[token_id][child_contract]

    def total_child_tokens(self, token_id: int, child_contract: str) -> int:
        """Get the total number of child tokens held by a token from a specific contract."""
        return len(self.child_tokens(token_id, child_contract))


class StateMachine:

    st_contract = contract_strategy("ERC721")
    st_token = strategy("uint", max_value=9)

    def __init__(cls, alice: Account, ERC721: ContractContainer, xhibit: Contract):
        cls.alice = alice
        cls.xhibit = xhibit

        # create 10 mock ERC721 contracts
        for _ in range(10):
            instance = alice.deploy(ERC721)
            # create 10 xhibit NFTs as well
            xhibit.mint(alice, {"from": alice})
            # create 10 NFTs in this contract instance
            for _ in range(10):
                instance._mint_for_testing(alice, {"from": alice})

    def setup(self):
        self.state = State()

    def rule_receive_child(
        self,
        st_contract: Contract,
        token_id: int = "st_token",
        receiving_token: int = "st_token",
    ):
        if st_contract.ownerOf(token_id) == self.alice:
            st_contract.safeTransferFrom(
                self.alice, self.xhibit, token_id, receiving_token, {"from": self.alice}
            )
            self.state.receive_child(receiving_token, str(st_contract), token_id)

    def rule_remove_child(
        self, st_contract: Contract, child_token: int = "st_token",
    ):
        if st_contract.ownerOf(child_token) == self.xhibit:
            from_token = self.xhibit.ownerOfChild(st_contract, child_token)[1]
            self.xhibit.transferChild(
                from_token, self.alice, st_contract, child_token, {"from": self.alice}
            )
            self.state.remove_child(from_token, str(st_contract), child_token)

    def invariant_totalChildContracts(self):
        # for each xhibit NFT verify the total # of child contracts
        for i in range(10):
            assert self.xhibit.totalChildContracts(
                i
            ) == self.state.total_child_contracts(i)

    def invariant_childContracts(self):
        # for each xhibit NFT
        for i in range(10):
            child_contracts = {
                self.xhibit.childContractByIndex(i, j)
                for j in range(self.state.total_child_contracts(i))
            }
            assert child_contracts == self.state.child_contracts(i)

    def invariant_totalChildTokens(self):
        # for each xhibit NFT
        for i in range(10):
            for child_contract in self.state.child_contracts(i):
                assert self.xhibit.totalChildTokens(
                    i, child_contract
                ) == self.state.total_child_tokens(i, child_contract)

    def invariant_childTokens(self):
        for i in range(10):
            for child_contract in self.state.child_contracts(i):
                child_tokens = {
                    self.xhibit.childTokenByIndex(i, child_contract, j)
                    for j in range(self.state.total_child_tokens(i, child_contract))
                }
                assert child_tokens == self.state.child_tokens(i, child_contract)


def test_state(alice, ERC721, state_machine, xhibit):
    state_machine(
        StateMachine, alice, ERC721, xhibit, settings=dict(stateful_step_count=25)
    )
