// SPDX-License-Identifier: BUSL-1.1
pragma solidity =0.7.6;

import './interfaces/IUniswapV3Factory.sol';

import './UniswapV3PoolDeployer.sol';
import './NoDelegateCall.sol';

import './UniswapV3Pool.sol';

/*
유니스왑V3에서 틱은 유동성 풀에서 특정 토큰 쌍에 대한 불연속적인 가격 수준입니다. 틱은 토큰 쌍의 현재 가격과 초기 가격의 비율로 정의되며, 
기본 가격 증가분의 배수로 표현됩니다. 각 틱은 고유한 정수 값으로 표시되며, 특정 틱 간격으로 유동성을 추가할 수 있습니다. 
예를 들어, 기본 가격 상승폭이 0.0001 이더리움이고 틱 간격이 10인 유니스왑V3 풀에서 각 틱은 1%의 가격 변화를 나타내며, 10번째 틱마다 유동성을 추가할 수 있습니다.
틱은 유니스왑V3 프로토콜에서 유동성 포지션, 수수료, 가격 계산에 사용됩니다. 사용자가 풀에 유동성을 추가하면 포지션은 틱 범위로 표시되며, 
사용자가 받는 수수료는 포지션의 크기와 틱 범위 내의 거래량에 비례합니다. 거래가 체결될 때 거래 가격은 거래 시점의 풀의 틱 레벨을 기준으로 계산됩니다.

전반적으로 틱은 유니스왑V3에서 유동성을 효율적으로 관리하고 가격을 계산하는 메커니즘을 제공합니다.

 */


/// @title Canonical Uniswap V3 factory
/// @notice Deploys Uniswap V3 pools and manages ownership and control over pool protocol fees
// 인터페이스 유니스왑V3팩토리, 유니스왑 풀 배포, 노 델리게이트콜을 상속한다. 
contract UniswapV3Factory is IUniswapV3Factory, UniswapV3PoolDeployer, NoDelegateCall {
    /// @inheritdoc IUniswapV3Factory
    //owner 주소 변수 선언 
    address public override owner;

    /// @inheritdoc IUniswapV3Factory
    /// Tick 스페이싱 변수 선언, uint24를 키로, int24를 밸류로 설정 
    mapping(uint24 => int24) public override feeAmountTickSpacing;
    /// @inheritdoc IUniswapV3Factory
    //Pool을 가져오는 매핑 
    mapping(address => mapping(address => mapping(uint24 => address))) public override getPool;

    constructor() {
        owner = msg.sender;
        emit OwnerChanged(address(0), msg.sender);

        feeAmountTickSpacing[500] = 10;
        emit FeeAmountEnabled(500, 10);
        
        feeAmountTickSpacing[3000] = 60;
        emit FeeAmountEnabled(3000, 60);
        
        feeAmountTickSpacing[10000] = 200;
        emit FeeAmountEnabled(10000, 200);
    }

    // Pool을 생성하는 함수
    /// @inheritdoc IUniswapV3Factory
    function createPool(
        address tokenA,
        address tokenB,
        uint24 fee
        //노델리게이트콜을 오버라이드, address 주소로 pool 주소를 받는다. 
    ) external override noDelegateCall returns (address pool) {
        require(tokenA != tokenB);
        (address token0, address token1) = tokenA < tokenB ? (tokenA, tokenB) : (tokenB, tokenA);
        require(token0 != address(0));
        int24 tickSpacing = feeAmountTickSpacing[fee];
        require(tickSpacing != 0);
        require(getPool[token0][token1][fee] == address(0));
        pool = deploy(address(this), token0, token1, fee, tickSpacing);
        getPool[token0][token1][fee] = pool;
        // populate mapping in the reverse direction, deliberate choice to avoid the cost of comparing addresses
        getPool[token1][token0][fee] = pool;
        emit PoolCreated(token0, token1, fee, tickSpacing, pool);
    }

    /// @inheritdoc IUniswapV3Factory
    //오너를 설정하는 함수 
    function setOwner(address _owner) external override {
        require(msg.sender == owner);
        emit OwnerChanged(owner, _owner);
        owner = _owner;
    }

    /// @inheritdoc IUniswapV3Factory
    //피어마운트를 
    function enableFeeAmount(uint24 fee, int24 tickSpacing) public override {
        require(msg.sender == owner);
        require(fee < 1000000);
        // tick spacing is capped at 16384 to prevent the situation where tickSpacing is so large that
        // TickBitmap#nextInitializedTickWithinOneWord overflows int24 container from a valid tick
        // 16384 ticks represents a >5x price change with ticks of 1 bips
        // 틱 간격이 16384로 제한되어 있어 tickSpacing이 너무 커서 다음과 같은 상황을 방지합니다.
        // TickBitmap#nextInitializedTickWithinOneWord가 유효한 틱에서 int24 컨테이너를 오버플로우합니다.
        // 16384 틱은 1빕의 틱으로 5배 이상의 가격 변화를 나타냅니다.
        require(tickSpacing > 0 && tickSpacing < 16384);
        require(feeAmountTickSpacing[fee] == 0);

        feeAmountTickSpacing[fee] = tickSpacing;
        emit FeeAmountEnabled(fee, tickSpacing);
    }
}
