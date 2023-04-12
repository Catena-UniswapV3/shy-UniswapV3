// SPDX-License-Identifier: BUSL-1.1
pragma solidity =0.7.6;

import './interfaces/IUniswapV3PoolDeployer.sol';

import './UniswapV3Pool.sol';

contract UniswapV3PoolDeployer is IUniswapV3PoolDeployer {
    struct Parameters {
        address factory; //팩토리 주소 
        address token0;  //토큰0 주소 
        address token1;  //토큰1 주소 
        uint24 fee;      //수수료 
        int24 tickSpacing; //집중유동성 구간과 유동성 구간이 아닌 곳을 구분하는 변수 
    }

    /// @inheritdoc IUniswapV3PoolDeployer
    // IUniswapV3PoolDeployer 상속했다는 것인가? 
    Parameters public override parameters;

    /// @dev Deploys a pool with the given parameters by transiently setting the parameters storage slot and then
    /// clearing it after deploying the pool.
    // 파라미터 저장 슬롯을 일시적으로 설정하여 주어진 파라미터가 포함된 풀을 배포한 다음
    /// 풀을 배포한 후 지웁니다.
    /// @param factory The contract address of the Uniswap V3 factory @param factory 유니스왑 V3 팩토리의 컨트랙트 주소입니다.
    /// @param token0 The first token of the pool by address sort  주소 정렬 순서에 따른 풀의 첫 번째 토큰입니다.
    /// @param token1 The second token of the pool by address sort order   주소 정렬 순서에 따른 풀의 두 번째 토큰
    /// @param fee The fee collected upon every swap in the pool, denominated in hundredths of a bip 풀에서 스왑할 때마다 징수하는 수수료로, 100분의 1 bip 단위로 표시합니다. bip란 무엇인가?? 
    /// @param tickSpacing The spacing between usable ticks 사용 가능한 틱 사이의 간격, 집중유동성구간과 아닌 구간 사이의 간격을 뜻하는 것인가? 아니면 집중유동성 구간을 뜻하는 것인가? 
    function deploy(
        address factory,
        address token0,
        address token1,
        uint24 fee,
        int24 tickSpacing
    ) internal returns (address pool) {
        parameters = Parameters({factory: factory, token0: token0, token1: token1, fee: fee, tickSpacing: tickSpacing}); //파라미터 1:1 대응? 
        pool = address(new UniswapV3Pool{salt: keccak256(abi.encode(token0, token1, fee))}()); //풀 변수에 address 함수 값을 넣고 이 안에 유니스왑v3 pool 주소를 넣는 것으로 보인다. 
        delete parameters; //위에 설정한 파라미터를 삭제하는 것으로 보인다. 
    }
}
