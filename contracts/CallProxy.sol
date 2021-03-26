// SPDX-License-Identifier: MIT
pragma solidity 0.7.6;

/// @title A simple proxy static caller
/// @author Edward Amor
/// @dev Allows a vyper contract to make an arbitrary static call and handle
///      if it is unsuccessful by returning an empty bytes variable.
contract CallProxy {
    /// @notice Proxy static call a target contract and handle error
    /// @dev Useful for vyper contract which can't handle errors with raw_call
    /// @param _target The address to call
    /// @param _calldata Arbitrary length data to send to `_target` should include signature and call data
    /// @return returnData Either the result of calling the target contract or an empty bytes array
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
