%lang starknet
from starkware.cairo.common.cairo_builtins import HashBuiltin
from starkware.cairo.common.uint256 import Uint256

from src.main import finalize_auction
from src.storage import auction_last_block, auction_highest_bid, finalized_auctions
from src.data import Bid

from tests.helpers.erc721 import erc721_helpers
from tests.helpers.erc20 import erc20_helpers
from tests.helpers.auction import auction_helpers
from tests.helpers.constants import AUCTION_ID, SELLER, BUYER_1

@external
func __setup__():
    erc20_helpers.deploy_contract()
    erc721_helpers.deploy_contract()
    return ()
end

@external
func test_finalize_happy_case_no_bids{
    syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr
}() -> ():
    alloc_locals
    let minimal_bid = Uint256(100, 0)
    let end_block = 100

    %{ expect_events({"name": "auction_finalized", "data": [ids.AUCTION_ID]}) %}

    auction_helpers.create_auction(minimal_bid, end_block)
    %{ roll(ids.end_block + 1) %}
    finalize_auction(AUCTION_ID)

    let (auction_status) = finalized_auctions.read(AUCTION_ID)
    assert auction_status = 1

    let (bid) = auction_highest_bid.read(AUCTION_ID)
    assert bid = Bid(amount=Uint256(0, 0), address=0)

    erc721_helpers.assert_has_token(SELLER, Uint256(0, 1))

    return ()
end

@external
func test_finalize_happy_case_with_bids{
    syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr
}() -> ():
    alloc_locals
    let minimal_bid = Uint256(100, 0)
    let end_block = 100
    let amount = 100

    %{ expect_events({"name": "auction_finalized", "data": [ids.AUCTION_ID]}) %}

    auction_helpers.create_auction(minimal_bid, end_block)
    auction_helpers.topped_bid(AUCTION_ID, BUYER_1, amount)

    erc20_helpers.assert_address_balance(SELLER, 0)

    %{ roll(ids.end_block + 1) %}
    finalize_auction(AUCTION_ID)

    let (auction_status) = finalized_auctions.read(AUCTION_ID)
    assert auction_status = 1

    let (bid) = auction_highest_bid.read(AUCTION_ID)
    assert bid = Bid(amount=minimal_bid, address=BUYER_1)

    erc721_helpers.assert_has_token(BUYER_1, Uint256(0, 1))
    erc20_helpers.assert_address_balance(SELLER, 100)

    return ()
end

@external
func test_finalize_still_active{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
    ) -> ():
    alloc_locals
    let minimal_bid = Uint256(100, 0)
    let end_block = 100

    auction_helpers.create_auction(minimal_bid, end_block)

    let (auction_status) = finalized_auctions.read(AUCTION_ID)
    assert auction_status = 0

    %{ expect_revert(error_message="Auction is still active") %}
    finalize_auction(AUCTION_ID)

    return ()
end

@external
func test_finalize_already_finalized{
    syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr
}() -> ():
    alloc_locals
    let minimal_bid = Uint256(100, 0)
    let end_block = 100

    auction_helpers.create_auction(minimal_bid, end_block)
    %{ roll(ids.end_block + 1) %}
    finalize_auction(AUCTION_ID)

    let (auction_status) = finalized_auctions.read(AUCTION_ID)
    assert auction_status = 1

    %{ expect_revert(error_message="Auction is already finalized") %}
    finalize_auction(AUCTION_ID)

    return ()
end
