// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

interface IERC165 {
    function supportsInterface(bytes4 interfaceID) external view returns (bool);
}

interface IERC721 is IERC165{
    function balanceOf(address _owner) external view returns (uint256);
    function ownerOf(uint256 _tokenId) external view returns (address);
    function safeTransferFrom(address _from, address _to, uint256 _tokenId, bytes calldata data) external payable;
    function safeTransferFrom(address _from, address _to, uint256 _tokenId) external payable;
    function transferFrom(address _from, address _to, uint256 _tokenId) external payable;
    function approve(address _approved, uint256 _tokenId) external payable;
    function setApprovalForAll(address _operator, bool _approved) external;
    function getApproved(uint256 _tokenId) external view returns (address);
    function isApprovedForAll(address _owner, address _operator) external view returns (bool);
}

interface IERC721Receiever{
    function onERC721Received(address operator, address from, uint tokenId, bytes calldata data) external returns (bytes4);
}

contract ERC721 is IERC721{
    event Transfer(address indexed _from, address indexed _to, uint256 indexed _tokenId);
    event Approval(address indexed _owner, address indexed _approved, uint256 indexed _tokenId);
    event ApprovalForAll(address indexed _owner, address indexed _operator, bool _approved);

    mapping(uint => address) internal _ownerOf;            //tokenidpf nft => owner address
    mapping(address => uint) internal _balanceOf;        //address => no. of nfts owned
    mapping(uint => address) internal _approvals;        //tokenId => address approved to manage the nft on behalf of the original owner.
                                                        
    mapping(address => mapping( address => bool)) public isApprovedForAll;   //owner=> permissionedaddress => true (also this is for a function in the IERc interface(setapprovalforall))                                      

    function supportsInterface(bytes4 interfaceId) external pure returns (bool){        //165
        return interfaceId == type(IERC721).interfaceId || interfaceId == type(IERC165).interfaceId; 
    }

    function balanceOf(address _owner) external view returns (uint256){
        require (_owner != address(0), "Owner cannot be 0 address");
        return _balanceOf[_owner];
    }

    function ownerOf(uint256 _tokenId) external view returns (address owner){
        owner = _ownerOf[_tokenId]; //owner var already defined     ^
        require (owner != address(0), "Owner cannot be 0 address");
    }   

    function setApprovalForAll(address _operator, bool _approved) external{
        isApprovedForAll[msg.sender][_operator] = _approved;
        emit ApprovalForAll(msg.sender, _operator, _approved);
    }
    
    function approve(address _approved, uint256 _tokenId) external payable{
        address owner = _ownerOf[_tokenId];
        require(msg.sender == owner || isApprovedForAll[owner][msg.sender] , "you are not the owner");
        _approvals[_tokenId] = _approved;
        emit Approval(owner, _approved, _tokenId);
    }

    function getApproved(uint256 _tokenId) external view returns (address){
        require (_ownerOf[_tokenId] != address(0), "Owner cannot be 0 address, token d.n.e");
        return _approvals[_tokenId];
    }
    
    //self defined func
    function _isApprovedOrOwner( address _owner, address _spender, uint _tokenId )internal view returns (bool) {
        return (_spender == _owner || isApprovedForAll[_owner][_spender]  || _spender == _approvals[_tokenId]);         
    }
    
    function transferFrom(address _from, address _to, uint256 _tokenId) public payable{   //
        require(_from == _ownerOf[_tokenId]);
        require (_ownerOf[_tokenId] != address(0), "Owner cannot be 0 address, token d.n.e");
        require(_isApprovedOrOwner(_from, msg.sender, _tokenId ), "not apporved");

        _balanceOf[_from]--;
        _balanceOf[_to]++;
        _ownerOf[_tokenId] = _to;

        delete _approvals[_tokenId];
        
        emit Transfer(_from, _to, _tokenId);
    }                    
    
    function safeTransferFrom(address _from, address _to, uint256 _tokenId, bytes calldata data) external payable{
          transferFrom(_from, _to, _tokenId);
        require(
            _to.code.length == 0 ||
            IERC721Receiever(_to).onERC721Received(msg.sender, _from, _tokenId, data)  == IERC721Receiever.onERC721Received.selector,
            "unsafe"                
        );
    }
    
    function safeTransferFrom(address _from, address _to, uint256 _tokenId) external payable{
        transferFrom(_from, _to, _tokenId);
        require(
            _to.code.length == 0 ||
            IERC721Receiever(_to).onERC721Received(msg.sender, _from, _tokenId, "")  == IERC721Receiever.onERC721Received.selector,
            "unsafe"                
        );
    }
    
    //function isApprovedForAll(address _owner, address _operator) external view returns (bool);
    
    function _mint(address _to, uint _tokenId ) internal {
        require(_to != address(0), "Owner cannot be 0 address");
        require(_ownerOf[_tokenId] == address(0), "token exists");  

        _balanceOf[_to]++;
        _ownerOf[_tokenId] = _to; 

        emit Transfer(address(0), _to, _tokenId);

    }

    function _burn(uint _tokenId) internal {
        address owner = _ownerOf[_tokenId];
        require(owner != address(0), "token dne");

        _balanceOf[owner]--;
        delete _ownerOf[_tokenId];
        delete _approvals[_tokenId];

        emit Transfer(owner, address(0), _tokenId);          
    }

}

contract MyNft is ERC721 {
    function  mint (address to, uint tokenId ) external {
        _mint(to, tokenId);
    }

    function burn(uint tokenId ) external {
        require (msg.sender == _ownerOf[tokenId]);
        _burn(tokenId);
    }
}
