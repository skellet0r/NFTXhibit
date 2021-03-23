// SPDX-License-Identifier: MIT
pragma solidity 0.7.6;
pragma experimental ABIEncoderV2;

contract CallProxy {
    function tryStaticCall(address _target, bytes calldata _calldata)
        external
        view
        returns (bytes memory returnData)
    {
        (bool success, bytes memory ret) = _target.staticcall(_calldata);
        if (success) {
            returnData = ret;
        } else {
            returnData = "";
        }
    }
}
