%lang starknet

from starkware.cairo.common.cairo_builtins import HashBuiltin
from starkware.starknet.common.syscalls import (
    get_caller_address,
    get_block_number,
    get_contract_address,
)
from starkware.cairo.common.uint256 import Uint256

from openzeppelin.token.erc721.IERC721 import IERC721

from src.main import (
    create_auction,
    AuctionData,
    auctions,
    auction_last_block,
    place_bid,
    finalized_auctions,
    finalize_auction,
)
from src.constants import AUCTION_PROLONGATION_ON_BID

from tests.helpers.erc721 import erc721_helpers
from tests.helpers.data import data_helpers
from tests.helpers.erc20 import erc20_helpers
from tests.helpers.auction import auction_helpers
from tests.helpers.constants import SELLER, AUCTION_ID, BUYER_1, BUYER_2

@external
func test_two_bids{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}() -> () {
    alloc_locals;
    local buyer_1_bid = 1000;
    local buyer_2_bid = 2000;
    let (auction_contract_address) = get_contract_address();
    let (current_block_number) = get_block_number();
    let auction_lifetime = 100;  // in blocks
    let token_id = Uint256(0, 1);
    let (local erc20_address) = erc20_helpers.get_address();
    let (local erc721_address) = erc721_helpers.get_address();
    local expected_auction: AuctionData = AuctionData(
        seller=SELLER,
        asset_id=token_id,
        min_bid_increment=Uint256(100, 0),
        erc20_address=erc20_address,
        erc721_address=erc721_address,
        );
    erc721_helpers.mint(SELLER, token_id);

    %{ end_prank = start_prank(ids.SELLER, ids.erc721_address) %}
    erc721_helpers.approve_for_auction(token_id);
    %{ end_prank() %}

    %{ end_prank = start_prank(ids.SELLER) %}
    create_auction(
        auction_id=AUCTION_ID,
        asset_id=expected_auction.asset_id,
        min_bid_increment=expected_auction.min_bid_increment,
        erc20_address=expected_auction.erc20_address,
        erc721_address=expected_auction.erc721_address,
        lifetime=auction_lifetime,
    );
    %{ end_prank() %}

    let (saved_auction) = auctions.read(AUCTION_ID);
    data_helpers.assert_auctions_equal(expected_auction, saved_auction);

    erc721_helpers.assert_has_token(auction_contract_address, token_id);

    // We'll place a bid in the last block to see if it is prolonged
    let (last_block) = auction_last_block.read(AUCTION_ID);
    %{ roll(ids.last_block) %}

    auction_helpers.topped_bid(AUCTION_ID, BUYER_1, buyer_1_bid);

    let expected_last_block = AUCTION_PROLONGATION_ON_BID + last_block;
    let (local last_block) = auction_last_block.read(AUCTION_ID);
    assert expected_last_block = last_block;

    auction_helpers.topped_bid(AUCTION_ID, BUYER_2, buyer_2_bid);

    // Make sure BUYER_1 got money back after buyer 2 placed a bid
    erc20_helpers.assert_address_balance(BUYER_1, buyer_1_bid);

    %{ roll(ids.last_block + 100) %}

    finalize_auction(AUCTION_ID);

    // Seller gets buyer_2_bid
    erc20_helpers.assert_address_balance(SELLER, buyer_2_bid);
    // Buyer gets the token
    erc721_helpers.assert_has_token(BUYER_2, token_id);
    // No money left for contract itself
    erc20_helpers.assert_address_balance(auction_contract_address, 0);

    let (is_closed) = finalized_auctions.read(AUCTION_ID);
    assert 1 = is_closed;

    %{ print("Congrats, contract seems to work properly! 🎉🎉🎉") %}

    return ();
}

@external
func __setup__() {
    erc20_helpers.deploy_contract();
    erc721_helpers.deploy_contract();
    return ();
}
