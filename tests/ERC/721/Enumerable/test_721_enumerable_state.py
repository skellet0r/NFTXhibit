from collections import defaultdict

from brownie.network.account import Accounts
from brownie.network.contract import Contract, ContractContainer
from brownie.test import strategy


class StateMachine:

    st_addr = strategy("address")
    st_random = strategy("uint256")

    def __init__(
        cls, accounts: Accounts, CallProxy: ContractContainer, Xhibit: ContractContainer
    ):
        cls.alice = accounts[0]
        call_proxy = cls.alice.deploy(CallProxy)

        cls.accounts = accounts
        cls.xhibit: Contract = cls.alice.deploy(Xhibit, call_proxy)

    def setup(self):
        self.total_supply = 0
        self.ownership = defaultdict(set)

    def rule_mint(self, st_addr):
        to = str(st_addr)
        self.xhibit.mint(to, {"from": self.alice})

        self.ownership[to].add(self.total_supply)
        self.total_supply += 1

    def rule_transfer(self, st_addr, st_random):
        if self.total_supply == 0:
            return
        to = str(st_addr)
        token_id = st_random % self.total_supply
        _from = str(self.xhibit.ownerOf(token_id))

        self.xhibit.transferFrom(_from, to, token_id, {"from": _from})

        self.ownership[_from].remove(token_id)
        self.ownership[to].add(token_id)

    def invariant_balanceOf(self):
        for acct in self.ownership.keys():
            assert self.xhibit.balanceOf(acct) == len(self.ownership[acct])

    def invariant_tokenOfOwnerByIndex(self):

        for acct in self.ownership.keys():
            tokens = {
                self.xhibit.tokenOfOwnerByIndex(acct, i)
                for i in range(len(self.ownership[acct]))
            }
            assert tokens == self.ownership[acct]


def test_state_machine(accounts, CallProxy, state_machine, Xhibit):
    state_machine(StateMachine, accounts, CallProxy, Xhibit)
