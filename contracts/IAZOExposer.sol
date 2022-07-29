//SPDX-License-Identifier: UNLICENSED
//ALL RIGHTS RESERVED
//**.finance

pragma solidity 0.8.6;



import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/// @title IAZO exposer 
/// @author **Finance
/// @notice Keeps track of all created IAZOs and exposes to outside world
contract IAZOExposer is Ownable {
    using EnumerableSet for EnumerableSet.AddressSet;

    address public IAZO_FACTORY;
    address public IAZO_LIQUIDITY_LOCKER;

    EnumerableSet.AddressSet private IAZOs;
    
    mapping(address => address) public IAZOAddressToTokenTimelockAddress;

    bool constant public isIAZOExposer = true;

    bool private initialized;

    event IAZORegistered(address indexed IAZOContract);
    event IAZOTimelockAdded(address indexed IAZOContract, address indexed TimelockContract);
    event LogInit();
    event SweepWithdraw(address indexed _to, IERC20 indexed token, uint256 balance);

    constructor() {
        initialized = false;
    }

    /// @notice Initialization of exposer
    /// @param _iazoFactory The address of the IAZO factory
    /// @param _liquidityLocker The address of the liquidity locker
    function initializeExposer(address _iazoFactory, address _liquidityLocker) external {
        require(!initialized, "already initialized");
        IAZO_FACTORY = _iazoFactory;
        IAZO_LIQUIDITY_LOCKER = _liquidityLocker;
        initialized = true;
        emit LogInit();
    }

    /// @notice Registers new IAZO address
    /// @param _iazoAddress The address of the IAZO
    function registerIAZO(address _iazoAddress) external {
        require(initialized, "not initialized");
        require(msg.sender == IAZO_FACTORY, "Forbidden");
        bool didAdd = IAZOs.add(_iazoAddress);
        if(didAdd) {
            emit IAZORegistered(_iazoAddress);
        }
    }

    /// @notice Check for IAZO registration
    /// @param _iazoAddress The address of the IAZO
    /// @return Whether the IAZO is registered or not
    function IAZOIsRegistered(address _iazoAddress)
        external
        view
        returns (bool)
    {
        return IAZOs.contains(_iazoAddress);
    }
    
    /// @notice Registers token timelock address and links with corresponding IAZO
    /// @param _iazoAddress The address of the IAZO
    /// @param _iazoTokenTimelock The address of the token timelock
    function addTokenTimelock(address _iazoAddress, address _iazoTokenTimelock) external {
        require(initialized, "not initialized");
        require(msg.sender == IAZO_LIQUIDITY_LOCKER, "Forbidden");
        require(IAZOAddressToTokenTimelockAddress[_iazoAddress] == address(0), "IAZO already has token timelock");
        IAZOAddressToTokenTimelockAddress[_iazoAddress] = _iazoTokenTimelock;
        emit IAZOTimelockAdded(_iazoAddress, _iazoTokenTimelock);
    }

    /// @notice Returns the token timelock address based on IAZO address
    /// @param _iazoAddress The address of the IAZO
    /// @return Token timelock address
    function getTokenTimelock(address _iazoAddress) external view returns (address){
        return IAZOAddressToTokenTimelockAddress[_iazoAddress];
    }

    /// @notice Returns the IAZO based on index of creation
    /// @param _index index of IAZO to be returned
    /// @return IAZO address
    function IAZOAtIndex(uint256 _index) external view returns (address) {
        return IAZOs.at(_index);
    }

    /// @notice Amount of IAZOs created total
    /// @return Amount of IAZOs created total
    function IAZOsLength() public view returns (uint256) {
        return IAZOs.length();
    }

    /// @notice A public function to sweep accidental ERC20 transfers to this contract. 
    /// @param _tokens Array of ERC20 addresses to sweep
    /// @param _to Address to send tokens to
    function sweepTokens(IERC20[] memory _tokens, address _to) external onlyOwner {
        for (uint256 index = 0; index < _tokens.length; index++) {
            IERC20 token = _tokens[index];
            uint256 balance = token.balanceOf(address(this));
            token.transfer(_to, balance);
            emit SweepWithdraw(_to, token, balance);
        }
    }
}
