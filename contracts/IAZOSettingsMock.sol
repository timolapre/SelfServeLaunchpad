//SPDX-License-Identifier: UNLICENSED
//ALL RIGHTS RESERVED
//**.finance

pragma solidity 0.8.6;



/// @title IAZO settings
/// @author **Finance
/// @notice Settings for new IAZOs
contract IAZOSettingsMock {

    struct Settings {
        address ADMIN_ADDRESS;
        address payable FEE_ADDRESS;
        address BURN_ADDRESS;
        uint256 BASE_FEE; // base fee percentage
        uint256 MAX_BASE_FEE; // max base fee percentage
        uint256 IAZO_TOKEN_FEE; // base fee percentage
        uint256 MAX_IAZO_TOKEN_FEE; // max base fee percentage
        uint256 NATIVE_CREATION_FEE; // fee to generate a IAZO contract on the platform
        uint256 MIN_LIQUIDITY_PERCENT;
        uint256 MAX_LIQUIDITY_PERCENT;
    }

    struct DelaySettings {
        uint256 MIN_IAZO_LENGTH; // minimum iazo active seconds
        uint256 MAX_IAZO_LENGTH; // maximum iazo active seconds
        uint256 MIN_LOCK_PERIOD;
        uint256 START_DELAY; // minium time away from creation that the iazo can start
        uint256 MAX_START_DELAY; // minium time away from creation that the iazo can start
    }

    event AdminTransferred(address indexed previousAdmin, address indexed newAdmin);
    event UpdateFeeAddress(address indexed previousFeeAddress, address indexed newFeeAddress);
    event UpdateFees(uint256 previousBaseFee, uint256 newBaseFee, uint256 previousIAZOTokenFee, uint256 newIAZOTokenFee, uint256 previousETHFee, uint256 newETHFee);
    event UpdateStartDelay(uint256 previousStartDelay, uint256 newStartDelay);
    event UpdateMinIAZOLength(uint256 previousMinLength, uint256 newMinLength);
    event UpdateMaxIAZOLength(uint256 previousMaxLength, uint256 newMaxLength);
    event UpdateMinLockPeriod(uint256 previousMinLockPeriod, uint256 newMinLockPeriod);
    event UpdateMinLiquidityPercent(uint256 previousMinLiquidityPercent, uint256 newMinLiquidityPercent);
    event UpdateMaxLiquidityPercent(uint256 previousMaxLiquidityPercent, uint256 newMaxLiquidityPercent);

    Settings public SETTINGS;
    DelaySettings public DELAY_SETTINGS;

    bool constant public isIAZOSettings = true;
    
    constructor(address admin, address feeAddress) {
        // Percentages are multiplied by 1000
        SETTINGS.ADMIN_ADDRESS = admin;
        SETTINGS.BASE_FEE = 15;  // .015 (1.5%) - initial base fee %
        SETTINGS.MAX_BASE_FEE = 300; // .30 (30%) - max base fee %
        SETTINGS.IAZO_TOKEN_FEE = 15;  // .015 (1.5%) - initial iazo fee %
        SETTINGS.MAX_IAZO_TOKEN_FEE = 300; // .30 (30%) - max iazo fee %
        SETTINGS.NATIVE_CREATION_FEE = 1e16; // .01 native token(s) // NOTE: for testing purposes
        /// @dev Fee address must be able to receive native currency
        SETTINGS.FEE_ADDRESS = payable(feeAddress); // Address that receives fees from IAZOs
        DELAY_SETTINGS.START_DELAY = 60; // 60 seconds // NOTE: For testing purposes
        DELAY_SETTINGS.MAX_START_DELAY = 2419000; // 28 days (in seconds)
        DELAY_SETTINGS.MIN_IAZO_LENGTH = 60; //  1 min // NOTE: For testing purposes
        DELAY_SETTINGS.MAX_IAZO_LENGTH = 1814000; // 3 weeks (in seconds)
        DELAY_SETTINGS.MIN_LOCK_PERIOD = 60; //  1 min // NOTE: For testing purposes
        SETTINGS.MIN_LIQUIDITY_PERCENT = 300; // .30 (30%) of raise matched with IAZO tokens
        SETTINGS.MAX_LIQUIDITY_PERCENT = 1000 - SETTINGS.BASE_FEE; // Can add everything after the base fee
        SETTINGS.BURN_ADDRESS = 0x000000000000000000000000000000000000dEaD;
    }

    modifier onlyAdmin {
        require(
            msg.sender == SETTINGS.ADMIN_ADDRESS,
            "not called by admin"
        );
        _;
    }

    function getAdminAddress() external view returns (address) {
        return SETTINGS.ADMIN_ADDRESS;
    }

    function isAdmin(address toCheck) external view returns (bool) {
        return SETTINGS.ADMIN_ADDRESS == toCheck;
    }

    function getMinStartTime() external view returns (uint256) {
        return DELAY_SETTINGS.START_DELAY + block.timestamp;
    }

    function getMaxIAZOLength() external view returns (uint256) {
        return DELAY_SETTINGS.MAX_IAZO_LENGTH;
    }

    function getMinIAZOLength() external view returns (uint256) {
        return DELAY_SETTINGS.MIN_IAZO_LENGTH;
    }
    
    function getBaseFee() external view returns (uint256) {
        return SETTINGS.BASE_FEE;
    }

    function getIAZOTokenFee() external view returns (uint256) {
        return SETTINGS.IAZO_TOKEN_FEE;
    }

    function getMaxBaseFee() external view returns (uint256) {
        return SETTINGS.MAX_BASE_FEE;
    }

    function getMaxIAZOTokenFee() external view returns (uint256) {
        return SETTINGS.MAX_IAZO_TOKEN_FEE;
    }
    
    function getNativeCreationFee() external view returns (uint256) {
        return SETTINGS.NATIVE_CREATION_FEE;
    }

    function getMinLockPeriod() external view returns (uint256) {
        return DELAY_SETTINGS.MIN_LOCK_PERIOD;
    }

    function getMinLiquidityPercent() external view returns (uint256) {
        return SETTINGS.MIN_LIQUIDITY_PERCENT;
    }

    function getMaxLiquidityPercent() external view returns (uint256) {
        return SETTINGS.MAX_LIQUIDITY_PERCENT;
    }
    
    function getFeeAddress() external view returns (address payable) {
        return SETTINGS.FEE_ADDRESS;
    }

    function getBurnAddress() external view returns (address) {
        return SETTINGS.BURN_ADDRESS;
    }

    function setAdminAddress(address _address) external onlyAdmin {
        emit AdminTransferred(SETTINGS.ADMIN_ADDRESS, _address);
        SETTINGS.ADMIN_ADDRESS = _address;
    }
    
    function setFeeAddress(address payable _feeAddress) external payable onlyAdmin {
        /// @dev insurance payment to verify _feeAddress can receive native tokens
        (bool feeAddressSuccess,) = _feeAddress.call{value: 1}("");
        require(feeAddressSuccess, "_feeAddress native transfer failed");
        /// @dev return native refund
        (bool success,) = msg.sender.call{value: msg.value - 1}("");
        require(success, "_feeAddress native transfer failed");
        emit UpdateFeeAddress(SETTINGS.FEE_ADDRESS, _feeAddress);
        SETTINGS.FEE_ADDRESS = _feeAddress;
    }
    
    /// @dev Because liquidity percent and the base fee are taken from the base percentage,
    ///  their combined value cannot be over 100%
    function setFees(uint256 _baseFee, uint256 _iazoTokenFee, uint256 _nativeCreationFee) external onlyAdmin {
        require(_baseFee <= SETTINGS.MAX_BASE_FEE, "base fee over max allowable");
        require(_baseFee <= 1000 - SETTINGS.MAX_LIQUIDITY_PERCENT, "base fee plus liquidity percent over 1000");
        require(_iazoTokenFee <= SETTINGS.MAX_IAZO_TOKEN_FEE, "IAZO token fee over max allowable");
        emit UpdateFees(SETTINGS.BASE_FEE, _baseFee, SETTINGS.IAZO_TOKEN_FEE, _iazoTokenFee, SETTINGS.NATIVE_CREATION_FEE, _nativeCreationFee);
        
        SETTINGS.BASE_FEE = _baseFee;
        SETTINGS.IAZO_TOKEN_FEE = _iazoTokenFee;
        SETTINGS.NATIVE_CREATION_FEE = _nativeCreationFee;
    }

    function setStartDelay(uint256 _newStartDelay) external onlyAdmin {
        require(_newStartDelay <= DELAY_SETTINGS.MAX_START_DELAY, "over max start delay");
        emit UpdateStartDelay(DELAY_SETTINGS.START_DELAY, _newStartDelay);
        DELAY_SETTINGS.START_DELAY = _newStartDelay;
    } 

    function setMaxIAZOLength(uint256 _maxLength) external onlyAdmin {
        require(_maxLength >= DELAY_SETTINGS.MIN_IAZO_LENGTH, "below min iazo length");
        emit UpdateMaxIAZOLength(DELAY_SETTINGS.MAX_IAZO_LENGTH, _maxLength);
        DELAY_SETTINGS.MAX_IAZO_LENGTH = _maxLength;
    }  

    function setMinIAZOLength(uint256 _minLength) external onlyAdmin {
        require(_minLength <= DELAY_SETTINGS.MAX_IAZO_LENGTH, "over max iazo length");
        emit UpdateMinIAZOLength(DELAY_SETTINGS.MIN_IAZO_LENGTH, _minLength);
        DELAY_SETTINGS.MIN_IAZO_LENGTH = _minLength;
    }   

    function setMinLockPeriod(uint256 _minLockPeriod) external onlyAdmin {
        emit UpdateMinLockPeriod(DELAY_SETTINGS.MIN_LOCK_PERIOD, _minLockPeriod);
        DELAY_SETTINGS.MIN_LOCK_PERIOD = _minLockPeriod;
    }

    function setMinLiquidityPercent(uint256 _minLiquidityPercent) external onlyAdmin {
        require(_minLiquidityPercent <= SETTINGS.MAX_LIQUIDITY_PERCENT, "over max liquidity percent");
        emit UpdateMinLiquidityPercent(SETTINGS.MIN_LIQUIDITY_PERCENT, _minLiquidityPercent);
        SETTINGS.MIN_LIQUIDITY_PERCENT = _minLiquidityPercent;
    }      

    /// @dev Because liquidity percent and the base fee are taken from the base percentage,
    ///  their combined value cannot be over 100%
    function setMaxLiquidityPercent(uint256 _maxLiquidityPercent) external onlyAdmin {
        require(_maxLiquidityPercent <= 1000 - SETTINGS.BASE_FEE, "liquidity percent plus base fee over 1000");
        emit UpdateMaxLiquidityPercent(SETTINGS.MAX_LIQUIDITY_PERCENT, _maxLiquidityPercent);
        SETTINGS.MAX_LIQUIDITY_PERCENT = _maxLiquidityPercent;
    }      
}