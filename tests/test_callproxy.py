def test_callproxy_returns_correct_data(alice, callproxy, nft):
    nft._mint_for_testing(alice)
    calldata = nft.balanceOf.encode_input(alice)

    result = callproxy.tryStaticCall(nft, calldata)
    assert nft.balanceOf.decode_output(result) == 1


def test_unsuccessful_callproxy_returns_empty_bytes(alice, callproxy, nft, xhibit):
    calldata = xhibit.owner.encode_input()

    result = callproxy.tryStaticCall(nft, calldata)
    assert len(result) == 0
