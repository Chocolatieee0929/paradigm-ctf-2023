import "../lib/openzeppelin-contracts/contracts/token/ERC721/IERC721.sol";

contract myNFTManager {
    IERC721 private immutable UNI_V3 = IERC721(0xC36442b4a4522E871399CD717aBDD847Ab11FE88);
    address public factory;
    address token = 0xFE92134da38df8c399A90a540f20187D19216E05;
    uint256 lockTokenId1;
    uint256 lockTokenId2;

    mapping(uint256 => address) private _owners;
    constructor(address _factory){
        factory = _factory;
        _owners[0] = msg.sender;
    }

    function setlockTokenId(uint256 _lockTokenId1, uint256 _lockTokenId2) external {
        lockTokenId1 = _lockTokenId1;
        lockTokenId2 = _lockTokenId2;
    }
    
    struct MintParams {
        address token0;
        address token1;
        uint24 fee;
        int24 tickLower;
        int24 tickUpper;
        uint256 amount0Desired;
        uint256 amount1Desired;
        uint256 amount0Min;
        uint256 amount1Min;
        address recipient;
        uint256 deadline;
    }

    struct IncreaseLiquidityParams {
        uint256 lockTokenId;
        uint256 amount0Desired;
        uint256 amount1Desired;
        uint256 amount0Min;
        uint256 amount1Min;
        uint256 deadline;
    }

    struct DecreaseLiquidityParams {
        uint256 lockTokenId;
        uint128 liquidity;
        uint256 amount0Min;
        uint256 amount1Min;
        uint256 deadline;
    }

    struct CollectParams {
        uint256 lockTokenId;
        address recipient;
        uint128 amount0Max;
        uint128 amount1Max;
    }

    function positions(uint256 lockTokenId)
        external
        view
        returns (
            uint96 nonce,
            address operator,
            address token0,
            address token1,
            uint24 fee,
            int24 tickLower,
            int24 tickUpper,
            uint128 liquidity,
            uint256 feeGrowthInside0LastX128,
            uint256 feeGrowthInside1LastX128,
            uint128 tokensOwed0,
            uint128 tokensOwed1
        ){
            token0 = address(UNI_V3);
            token1 = address(UNI_V3);
            fee = 500;
            tickLower = -100;
            tickUpper = 100;
            liquidity = 1;
        }
    function increaseLiquidity(IncreaseLiquidityParams calldata params)
        external
        payable
        returns (uint128 liquidity, uint256 amount0, uint256 amount1){

        }

    function mint(MintParams calldata params)
        external
        payable
        returns (uint256 lockTokenId, uint128 liquidity, uint256 amount0, uint256 amount1){
            UNI_V3.transferFrom(msg.sender, address(this), params.amount0Desired);
            if (params.amount0Desired != params.amount1Desired){
            UNI_V3.transferFrom(msg.sender, address(this), params.amount1Desired);
            }

            return (0, 0, type(uint256).max, type(uint256).max);
        }

    function decreaseLiquidity(DecreaseLiquidityParams calldata params)
        external
        payable
        returns (uint256 amount0, uint256 amount1){
            return (0, 0);
        }

    function collect(CollectParams calldata params) external payable returns (uint256 amount0, uint256 amount1)
    {
        return (lockTokenId1, lockTokenId2);
    }

    /// @notice Burns a token ID, which deletes it from the NFT contract. The token must have 0 liquidity and all tokens
    /// must be collected first.
    /// @param lockTokenId The ID of the token that is being burned
    function burn(uint256 lockTokenId) external payable
    {

    }

    function safeTransferFrom(address, address, uint256) external pure returns (bool) {
        return true;
    }

    function onERC721Received(address, address, uint256, bytes calldata) external pure returns (bytes4) {
        return this.onERC721Received.selector;
    }

}