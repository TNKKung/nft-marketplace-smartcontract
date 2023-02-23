// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC721/ERC721.sol)

pragma solidity ^0.8.4;


import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/IERC721Metadata.sol";
import "@openzeppelin/contracts/utils/introspection/ERC165.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/utils/Strings.sol";


contract nft is Context, ERC165,IERC721Metadata {
    using Address for address;
    using Strings for uint256;

    using Counters for Counters.Counter;

    Counters.Counter private _tokenIds;

    string private _name; 

    string private _symbol;

    struct NFT {
         address _owners;
         address[] _collaborators;
         uint256[] _collaboratorsPercentage;
         string _tokenURI;
         uint256 counterTranfers;
     }


    // mapping(uint256 => address) private _owners;

    // mapping(uint256 => address[]) private _collaborators;

    // mapping(uint256 => uint256[]) private _collaboratorsPercentage;

    mapping(address => uint256) private _balances;                                                          

    mapping(uint256 => address) private _tokenApprovals;

    mapping(address => mapping(address => bool)) private _operatorApprovals;

    // mapping(uint256 => string) private _tokenURIs;

    // mapping(uint256 => uint256) private counterTranfers;

    mapping(uint256 => NFT) private tokenIdToNFT;



    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }


    event Mint (
        uint256 tokenId,
        address owner
    );
    


    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165, IERC165) returns (bool) {
        return
            interfaceId == type(IERC721).interfaceId ||
            interfaceId == type(IERC721Metadata).interfaceId ||
            super.supportsInterface(interfaceId);
    }

   function _incrementCounterTransfers(uint256 tokenId) public {
        uint256 count = tokenIdToNFT[tokenId].counterTranfers;
        tokenIdToNFT[tokenId].counterTranfers = count+1;
    }

     function getCounterTransfers(uint256 tokenId) public view returns (uint256) {
        uint256 count = tokenIdToNFT[tokenId].counterTranfers;
        return count;
    }

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "ERC721URIStorage: URI query for nonexistent token");

        string memory _tokenUri = tokenIdToNFT[tokenId]._tokenURI;
        string memory base = _baseURI();

        if (bytes(base).length == 0) {
            return _tokenUri;
        }
        if (bytes(_tokenUri).length > 0) {
            return string(abi.encodePacked(base, _tokenUri));
        }

        return _tokenURI(tokenId);
    }


    function _setTokenURI(uint256 tokenId, string memory _tokenUri) internal virtual {
        require(_exists(tokenId), "ERC721URIStorage: URI set of nonexistent token");
        tokenIdToNFT[tokenId]._tokenURI = _tokenUri;
    }



    function balanceOf(address owner) public view virtual override returns (uint256) {
        require(owner != address(0), "ERC721: address zero is not a valid owner");
        return _balances[owner];
    }


    function ownerOf(uint256 tokenId) public view virtual override returns (address) {
        address owner = tokenIdToNFT[tokenId]._owners;
        require(owner != address(0), "ERC721: invalid token ID");
        return owner;
    }

    function getTokenCurrent() public view virtual returns (string memory) {
        return _tokenIds.current().toString();
    }

     function collaboratotOf(uint256 tokenId) public view virtual returns (address[] memory) {
        address[] memory collaborator = tokenIdToNFT[tokenId]._collaborators;
        return collaborator;
    }

    function collaboratotPercentageOf(uint256 tokenId) public view virtual returns (uint256[] memory) {
        uint256[] memory collaboratorPercentage = tokenIdToNFT[tokenId]._collaboratorsPercentage;
        return collaboratorPercentage;
    }

    function name() public view virtual override returns (string memory) {
        return _name;
    }
 
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    function _tokenURI(uint256 tokenId) private view returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");

        string memory baseURI = _baseURI();
        return bytes(baseURI).length > 0 ? string(abi.encodePacked(baseURI, tokenId.toString())) : "";
    }

    function _baseURI() internal view virtual returns (string memory) {
        return "";
    }

    function approve(address to, uint256 tokenId) public virtual override {
        address owner = nft.ownerOf(tokenId);
        require(to != owner, "ERC721: approval to current owner");

        require(
            _msgSender() == owner || isApprovedForAll(owner, _msgSender()),
            "ERC721: approve caller is not token owner or approved for all"
        );

        _approve(to, tokenId);
    }

 
    function getApproved(uint256 tokenId) public view virtual override returns (address) {
        _requireMinted(tokenId);

        return _tokenApprovals[tokenId];
    }

  
    function setApprovalForAll(address operator, bool approved) public virtual override {
        _setApprovalForAll(_msgSender(), operator, approved);
    }


    function isApprovedForAll(address owner, address operator) public view virtual override returns (bool) {
        return _operatorApprovals[owner][operator];
    }


    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {

        _transfer(from, to, tokenId);
    }


    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        safeTransferFrom(from, to, tokenId, "");
    }


    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    ) public virtual override {
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: caller is not token owner or approved");
        _safeTransfer(from, to, tokenId, data);
    }

     function mint(address[] memory collaborator,uint256[] memory collaboratorPercent,string memory uri) public {
          _tokenIds.increment();
        uint256 tokenId = _tokenIds.current();

        _safeMint(msg.sender, collaborator,collaboratorPercent,tokenId);
        _setTokenURI(tokenId, uri);
    }

    

    function _safeTransfer(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    ) internal virtual {
        _transfer(from, to, tokenId);
        require(_checkOnERC721Received(from, to, tokenId, data), "ERC721: transfer to non ERC721Receiver implementer");
    }

    function _exists(uint256 tokenId) internal view virtual returns (bool) {
        return tokenIdToNFT[tokenId]._owners != address(0);
    }


    function _isApprovedOrOwner(address spender, uint256 tokenId) internal view virtual returns (bool) {
        address owner = nft.ownerOf(tokenId);
        return (spender == owner || isApprovedForAll(owner, spender) || getApproved(tokenId) == spender);
    }

    function _safeMint(address to,address[] memory collaborator,uint256[] memory collaboratorPercent,uint256 tokenId) internal virtual {
        _safeMint(to, collaborator,collaboratorPercent,tokenId, "");
    }

    function _safeMint(
        address to,
        address[] memory collaborator,
        uint256[] memory  collaboratorPercent,
        uint256 tokenId,
        bytes memory data
    ) internal virtual {
        _mint(to, collaborator,collaboratorPercent, tokenId);
        require(
            _checkOnERC721Received(address(0), to, tokenId, data),
            "ERC721: transfer to non ERC721Receiver implementer"
        );
    }

    function _mint(address to,address[] memory collaborator,uint256[] memory collaboratorPercent,uint256 tokenId) internal virtual {
        require(to != address(0), "ERC721: mint to the zero address");
        require(!_exists(tokenId), "ERC721: token already minted");

        _beforeTokenTransfer(address(0), to, tokenId);

        require(!_exists(tokenId), "ERC721: token already minted");

        unchecked {
            _balances[to] += 1;
        }

                 emit Mint(
                tokenId,
                     to
                );

        tokenIdToNFT[tokenId]._owners = to;
        tokenIdToNFT[tokenId]._collaborators = collaborator;
        tokenIdToNFT[tokenId]._collaboratorsPercentage = collaboratorPercent;

        emit Transfer(address(0), to, tokenId);

        _afterTokenTransfer(address(0), to, tokenId);
    }


    function _burn(uint256 tokenId) internal virtual {
        address owner = nft.ownerOf(tokenId);

        _beforeTokenTransfer(owner, address(0), tokenId);

        owner = nft.ownerOf(tokenId);

        delete _tokenApprovals[tokenId];

        unchecked {

            _balances[owner] -= 1;
        }
        delete tokenIdToNFT[tokenId]._owners;

        emit Transfer(owner, address(0), tokenId);

        _afterTokenTransfer(owner, address(0), tokenId);
    }



    function _transfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {
        require(nft.ownerOf(tokenId) == from, "ERC721: transfer from incorrect owner");
        require(to != address(0), "ERC721: transfer to the zero address");

        _beforeTokenTransfer(from, to, tokenId);

        require(nft.ownerOf(tokenId) == from, "ERC721: transfer from incorrect owner");

        // Clear approvals from the previous owner
        delete _tokenApprovals[tokenId];

        unchecked {

            _balances[from] -= 1;
            _balances[to] += 1;
        }
        _incrementCounterTransfers(tokenId);
        tokenIdToNFT[tokenId]._owners = to;

        emit Transfer(from, to, tokenId);

        _afterTokenTransfer(from, to, tokenId);
    }


    function _approve(address to, uint256 tokenId) internal virtual {
        _tokenApprovals[tokenId] = to;
        emit Approval(nft.ownerOf(tokenId), to, tokenId);
    }

    function _setApprovalForAll(
        address owner,
        address operator,
        bool approved
    ) internal virtual {
        require(owner != operator, "ERC721: approve to caller");
        _operatorApprovals[owner][operator] = approved;
        emit ApprovalForAll(owner, operator, approved);
    }

    function _requireMinted(uint256 tokenId) internal view virtual {
        require(_exists(tokenId), "ERC721: invalid token ID");
    }


    function _checkOnERC721Received(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    ) private returns (bool) {
        if (to.isContract()) {
            try IERC721Receiver(to).onERC721Received(_msgSender(), from, tokenId, data) returns (bytes4 retval) {
                return retval == IERC721Receiver.onERC721Received.selector;
            } catch (bytes memory reason) {
                if (reason.length == 0) {
                    revert("ERC721: transfer to non ERC721Receiver implementer");
                } else {
                    /// @solidity memory-safe-assembly
                    assembly {
                        revert(add(32, reason), mload(reason))
                    }
                }
            }
        } else {
            return true;
        }
    }


    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {}

    function _afterTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {}

}