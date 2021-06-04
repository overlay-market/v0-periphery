// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC1155/utils/ERC1155Holder.sol";

contract OverlayV1MagicERC20 is ERC1155Holder, ERC20 {
    using SafeERC20 for IERC20;

    // OverlayV1Market to trade on
    address public immutable market;
    // Underlying token being replicated as a high-yield (funding) synthetic
    address public immutable underlying;

    constructor(
        string memory _name,
        string memory _symbol,
        address _market,
        address _underlying
    ) ERC20(_name, _symbol) {
        market = _market;
        underlying = _underlying;
    }

    /// @notice Constructs portfolio of market positions and spot tokens with value of synthetic
    /// @dev Override for each specific synthetic given required allocations of positions and spot tokens
    function construct(uint256 amountIn) internal returns (uint256 amountOut) {
    }

    /// @notice Destructs synthetic portfolio into underlying
    /// @dev Override for each specific synthetic given required allocations of positions and spot tokens
    function destruct(uint256 amountIn) internal returns (uint256 amountOut) {
    }

    /// @notice Mints funding synthetics for given amount of underlying to recipient
    function mint(address recipient, uint256 amount) external {
        IERC20(underlying).safeTransferFrom(msg.sender, address(this), amount);
        uint256 amountOut = construct(amount);
        _mint(recipient, amountOut);
    }

    /// @notice Burns given amount of funding synthetics and returns underlying plus interest to recipient
    function burn(address recipient, uint256 amount) external {
        _burn(msg.sender, amount);
        uint256 amountOut = destruct(amount);
        IERC20(underlying).safeTransfer(recipient, amountOut);
    }
}
