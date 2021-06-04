// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC1155/utils/ERC1155Holder.sol";
import "@overlay/v1-core/contracts/interfaces/IOverlayV1Market.sol";

contract OverlayV1MagicERC20 is ERC1155Holder, ERC20 {
    using SafeERC20 for IERC20;

    // OverlayV1Market to trade on
    address public immutable market;
    // Underlying token being replicated as a high-yield (funding) synthetic
    address public immutable underlying;
    // Counter token to the underlying in pair
    address public immutable counter;

    constructor(
        string memory _name,
        string memory _symbol,
        address _market,
        address _underlying,
        address _counter
    ) ERC20(_name, _symbol) {
        market = _market;
        underlying = _underlying;
        counter = _counter;
    }

    /// @notice Constructs portfolio of market positions and spot tokens with value of synthetic
    /// @dev Override for each specific synthetic given required allocations of positions and spot tokens
    function construct(uint256 amountIn) internal returns (uint256 amountOut) {
    }

    /// @notice Destructs synthetic portfolio into underlying
    /// @dev Override for each specific synthetic given required allocations of positions and spot tokens
    function destruct(uint256 amountIn) internal returns (uint256 amountOut) {
    }

    /// @notice Gets counter token amount needed to make an amount out of synthetic from market position token
    /// @dev Override for each specific synthetic given required allocations of positions and spot tokens
    function getAmountsFromPosition(
        uint256 positionId,
        uint256 share
    ) internal returns (uint256 counterAmount, uint256 amountOut) {
    }

    /// @notice Mints funding synthetic for given amount of underlying to recipient
    function mint(address recipient, uint256 amount) external {
        IERC20(underlying).safeTransferFrom(msg.sender, address(this), amount);
        uint256 amountOut = construct(amount);
        _mint(recipient, amountOut);
    }

    /// @notice Burns given amount of funding synthetic and returns underlying plus interest to recipient
    function burn(address recipient, uint256 amount) external {
        _burn(msg.sender, amount);
        uint256 amountOut = destruct(amount);
        IERC20(underlying).safeTransfer(recipient, amountOut);
    }

    /// @notice Deposit built position + spot tokens needed to mint synthetic
    function deposit(address recipient, uint256 positionId, uint256 share) external {
        IOverlayV1Market(market).safeTransferFrom(msg.sender, address(this), positionId, share, "");
        (uint256 counterAmount, uint256 amountOut) = getAmountsFromPosition(positionId, share);
        IERC20(counter).safeTransferFrom(msg.sender, address(this), counterAmount);
        _mint(recipient, amountOut);
    }

    /// @notice Batch deposit built position + spot tokens needed to mint synthetic
    function batchDeposit(address recipient, uint256[] memory positionIds, uint256[] memory shares) external {
        IOverlayV1Market(market).safeBatchTransferFrom(msg.sender, address(this), positionIds, shares, "");

        uint256 counterAmount;
        uint256 amountOut;
        for (uint256 i=0; i < positionIds.length; ++i) {
            uint256 positionId = positionIds[i];
            uint256 share = shares[i];
            (uint256 _counterAmount, uint256 _amountOut) = getAmountsFromPosition(positionId, share);
            counterAmount += _counterAmount;
            amountOut += _amountOut;
        }
        IERC20(counter).safeTransferFrom(msg.sender, address(this), counterAmount);
        _mint(recipient, amountOut);
    }
}
