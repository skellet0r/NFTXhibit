import pytest
from brownie.network.account import Account, Accounts, EthAddress
from brownie.network.contract import Contract, ContractContainer


@pytest.fixture(scope="module")
def alice(accounts: Accounts) -> Account:
    """Alice the first available test account."""
    return accounts[0]


@pytest.fixture(scope="module")
def bob(accounts: Accounts) -> Account:
    """Bob the second available test account."""
    return accounts[1]


@pytest.fixture(scope="module")
def charlie(accounts: Accounts) -> Account:
    """Charlie the third available test account."""
    return accounts[2]


@pytest.fixture(scope="module")
def zero_address() -> EthAddress:
    """The canonical ethereum zero address."""
    return EthAddress("0x0000000000000000000000000000000000000000")


@pytest.fixture(scope="module")
def nft(alice: Account, ERC721: ContractContainer) -> Contract:
    """Instance of the Xhibit contract."""
    return alice.deploy(ERC721)


@pytest.fixture(scope="module")
def xhibit(alice: Account, Xhibit: ContractContainer) -> Contract:
    """Instance of the Xhibit contract."""
    return alice.deploy(Xhibit)


@pytest.fixture(scope="module")
def nft(alice: Account, ERC721: ContractContainer) -> Contract:
    """Instance of a mock ERC721 contract."""
    return alice.deploy(ERC721)


@pytest.fixture(autouse=True)
def isolate(fn_isolation):
    """Isolate each test function."""
    pass
