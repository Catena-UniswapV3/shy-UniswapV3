// SPDX-License-Identifier: BUSL-1.1
pragma solidity =0.7.6;

/// @title Prevents delegatecall to a contract
/// @notice Base contract that provides a modifier for preventing delegatecall to methods in a child contract
abstract contract NoDelegateCall {
    /// @dev The original address of this contract
    //address 주소 변수 설정 
    address private immutable original;

    //생성자에서 현재 주소를 original 변수로 설정 
    constructor() {
        // Immutables are computed in the init code of the contract, and then inlined into the deployed bytecode.
        // In other words, this variable won't change when it's checked at runtime.
        original = address(this);
    }

    
    /// @dev Private method is used instead of inlining into modifier because modifiers are copied into each method,
    ///     and the use of immutable means the address bytes are copied in every place the modifier is used.
    /// modifier가 각 메서드에 복사되기 때문에 modifier에 inlining하는 대신 Private 메서드가 사용됩니다,
    /// 그리고 immutable을 사용하면 modifier가 사용되는 모든 위치에 주소 바이트가 복사됩니다.
    function checkNotDelegateCall() private view {
        require(address(this) == original);
    }

    /// @notice Prevents delegatecall into the modified method
    //수정된 메서드에 대한 delegatecall 호출 방지
    modifier noDelegateCall() {
        checkNotDelegateCall();
        _;
    }
}
