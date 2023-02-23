// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/utils/Counters.sol";
import "github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/token/ERC721/ERC721.sol";
import "github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/security/ReentrancyGuard.sol";
import "github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/utils/math/SafeMath.sol";


interface INFT {
    function getCounterTransfers(uint256 tokenId) external view returns (uint256);
    function collaboratotOf(uint256 tokenId) external view returns (address[] memory);
    function collaboratotPercentageOf(uint256 tokenId) external view returns (uint256[] memory);
}


contract marketplace is ReentrancyGuard{
    using Counters for Counters.Counter;
    using SafeMath for uint256;
    Counters.Counter private _itemIds;
    Counters.Counter private _itemsSold;


     address public owner;
        uint256 listingPrice = 0.025 ether;
     
     constructor() {
        owner = msg.sender;
     }

     
     struct MarketItem {
        uint itemId;
        address nftContract;
        uint256 tokenId;
        address payable seller;
        address payable owner;
        uint256 price;
        bool sold;
     }
     
     mapping(uint256 => MarketItem) private idToMarketItem;
     
     event List (
        uint indexed itemId,
        address indexed nftContract,
        uint256 indexed tokenId,
        address seller,
        address owner,
        uint256 price,
        bool sold
     );

     event Unlist (
        uint indexed itemId,
        address owner
     );
     
     event Sale (
        uint indexed itemId,
        address owner,
        uint price
     );

       
     
    
    
    function listedNFTItem(
        address nftContract,
        uint256 tokenId,
        uint256 price
        ) public payable nonReentrant {
            require(price > 0, "Price must be greater than 0");
            
            _itemIds.increment();
            uint256 itemId = _itemIds.current();
  
            idToMarketItem[itemId] =  MarketItem(
                itemId,
                nftContract,
                tokenId,
                payable(msg.sender),
                payable(address(0)),
                price,
                false
            );

            emit List(
                itemId,
                nftContract,
                tokenId,
                msg.sender,
                address(0),
                price,
                false
            );
            
            IERC721(nftContract).transferFrom(msg.sender, address(this), tokenId);
                
            
        }

    function itemFromTokenId(uint256 tokenId) public view returns (uint256) {
        uint itemCount = _itemIds.current();
        uint currentIndex = 0;

        MarketItem memory items;
        for (uint i = 0; i < itemCount; i++) {
            if (idToMarketItem[i + 1].tokenId == tokenId) {
                uint currentId = i + 1;
                MarketItem storage currentItem = idToMarketItem[currentId];
                items = currentItem;
                currentIndex += 1;
            }
        }
        return items.itemId;
    }

    function priceFromTokenId(uint256 tokenId) public view returns (uint256) {
        uint itemCount = _itemIds.current();
        uint currentIndex = 0;

        MarketItem memory items;
        for (uint i = 0; i < itemCount; i++) {
            if (idToMarketItem[i + 1].tokenId == tokenId) {
                uint currentId = i + 1;
                MarketItem storage currentItem = idToMarketItem[currentId];
                items = currentItem;
                currentIndex += 1;
            }
        }
        return items.price;
    }
 
    function saleNFTItem(
        address nftContract,
        uint256 itemId
        ) public payable  {
            uint tokenId = idToMarketItem[itemId].tokenId;
            address seller = idToMarketItem[itemId].seller;
            uint256 price = idToMarketItem[itemId].price;

            require(msg.value == price, "Value must be equal price");
            emit Sale(
                itemId,
                msg.sender,
                price
            );
 
            address[] memory itemCollaborator = INFT(nftContract).collaboratotOf(tokenId);
            uint256[] memory itemCollaboratorPercent = INFT(nftContract).collaboratotPercentageOf(tokenId);

            uint256 count = INFT(nftContract).getCounterTransfers(tokenId);

            if(count > 1 ){
                if(itemCollaborator.length == 1){
                    uint256 sumPercentOfSeller = 100 - itemCollaboratorPercent[0];
                    payable(seller).transfer(msg.value * sumPercentOfSeller/100);
                    payable(itemCollaborator[0]).transfer(msg.value * itemCollaboratorPercent[0]/100);
                }else{
                    uint256 sumCollabPercent = itemCollaboratorPercent[0]+itemCollaboratorPercent[1];
                    uint256 sumPercentOfSeller = 100 - sumCollabPercent;
                    payable(seller).transfer(msg.value * sumPercentOfSeller/100);
                    payable(itemCollaborator[0]).transfer(msg.value * itemCollaboratorPercent[0]/100);
                    payable(itemCollaborator[1]).transfer(msg.value * itemCollaboratorPercent[1]/100);
                }
            }else{
                if(itemCollaborator.length == 1){
                    payable(itemCollaborator[0]).transfer(msg.value);         
                }else{
                    uint256 sumCollabPercent = itemCollaboratorPercent[0]+itemCollaboratorPercent[1];
                    payable(itemCollaborator[0]).transfer(msg.value * itemCollaboratorPercent[0]/sumCollabPercent);
                    payable(itemCollaborator[1]).transfer(msg.value * itemCollaboratorPercent[1]/sumCollabPercent);
                }
                
            }
            
            IERC721(nftContract).transferFrom(address(this), msg.sender, tokenId);
            idToMarketItem[itemId].owner = payable(msg.sender);
            _itemsSold.increment();
            idToMarketItem[itemId].sold = true;
        }

        function unListNFTItem(
        address nftContract,
        uint256 itemId
        ) public payable nonReentrant {
            uint tokenId = idToMarketItem[itemId].tokenId;
            bool sold = idToMarketItem[itemId].sold;
            address ownerNFT = idToMarketItem[itemId].seller;
            // address seller = idToMarketItem[tokenId].seller;
            require(sold != true, "This Sale has alredy finnished");
            require(ownerNFT == msg.sender,"Only seller may unlist an item");

            emit Unlist(
                itemId,
                msg.sender
                );

            IERC721(nftContract).transferFrom(address(this), ownerNFT, tokenId);
            idToMarketItem[itemId].owner = payable(msg.sender);
            _itemsSold.increment();
            idToMarketItem[itemId].sold = true;
        }

        
    function fetchNFTItems() public view returns (MarketItem[] memory) {
        uint itemCount = _itemIds.current();
        uint unsoldItemCount = _itemIds.current() - _itemsSold.current();
        uint currentIndex = 0;

        MarketItem[] memory items = new MarketItem[](unsoldItemCount);
        for (uint i = 0; i < itemCount; i++) {
            if (idToMarketItem[i + 1].owner == address(0)) {
                uint currentId = i + 1;
                MarketItem storage currentItem = idToMarketItem[currentId];
                items[currentIndex] = currentItem;
                currentIndex += 1;
            }
        }
        return items;
    }
      
}

