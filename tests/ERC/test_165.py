def test_supportsInterface_returns_true_for_erc_165(xhibit):
    assert xhibit.supportsInterface("0x01ffc9a7") is True


def test_supportsInterface_returns_false_for_bytes4_max(xhibit):
    assert xhibit.supportsInterface("0xffffffff") is False
