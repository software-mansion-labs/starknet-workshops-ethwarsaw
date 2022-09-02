%lang starknet
from starkware.cairo.common.cairo_builtins import HashBuiltin
from starkware.cairo.common.uint256 import Uint256
from starkware.starknet.common.syscalls import get_contract_address

from src.main import place_bid
from src.storage import auction_last_block, auction_highest_bid, finalized_auctions
from src.constants import AUCTION_PROLONGATION_ON_BID

from tests.helpers.erc721 import erc721_helpers
from tests.helpers.erc20 import erc20_helpers
from tests.helpers.auction import auction_helpers
from tests.helpers.constants import SELLER, AUCTION_ID, BUYER_1, BUYER_2

@external
func __setup__():
    erc20_helpers.deploy_contract()
    erc721_helpers.deploy_contract()
    return ()
end

@external
func test_placed_bid_happy_case{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
    ) -> ():
    alloc_locals
    let minimal_bid = Uint256(100, 0)
    let end_block = 100

    %{ expect_events({"name": "bid_placed", "data": [ids.AUCTION_ID, 100, 0]}) %}

    auction_helpers.create_auction(minimal_bid, end_block)
    auction_helpers.topped_bid(AUCTION_ID, BUYER_1, 100)

    let (current_last_block) = auction_last_block.read(AUCTION_ID)
    assert current_last_block = end_block

    let (current_highest_bid) = auction_highest_bid.read(AUCTION_ID)
    assert current_highest_bid.amount = minimal_bid
    assert current_highest_bid.address = BUYER_1

    return ()
end

@external
func test_placed_bid_happy_case_with_previous_bid{
    syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr
}() -> ():
    alloc_locals
    let minimal_bid = Uint256(100, 0)
    let end_block = 100

    %{
        expect_events({"name": "bid_placed", "data": [ids.AUCTION_ID, 100, 0]})
        expect_events({"name": "bid_placed", "data": [ids.AUCTION_ID, 200, 0]})
    %}

    auction_helpers.create_auction(minimal_bid, end_block)
    auction_helpers.topped_bid(AUCTION_ID, BUYER_1, 100)

    %{ roll(ids.end_block) %}
    auction_helpers.topped_bid(AUCTION_ID, BUYER_2, 200)

    let (current_last_block) = auction_last_block.read(AUCTION_ID)
    assert current_last_block = end_block + AUCTION_PROLONGATION_ON_BID

    let (current_highest_bid) = auction_highest_bid.read(AUCTION_ID)
    assert current_highest_bid.amount = Uint256(200, 0)
    assert current_highest_bid.address = BUYER_2

    erc20_helpers.assert_address_balance(BUYER_1, 100)

    return ()
end

# In this case user places two bids: one with half of money owned and then with all money owned.
# It will fail if old bid is returned _after_ securing new bid.
@external
func test_user_placing_two_bids_in_a_row{
    syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr
}() -> ():
    alloc_locals
    let (auction_contract_address) = get_contract_address()
    let minimal_bid = Uint256(50, 0)
    let end_block = 100
    let amount = 200

    auction_helpers.create_auction(minimal_bid, end_block)

    %{
        expect_events({"name": "bid_placed", "data": [ids.AUCTION_ID, 200, 0]})
        expect_events({"name": "bid_placed", "data": [ids.AUCTION_ID, 400, 0]})
    %}

    erc20_helpers.top_up_address(BUYER_1, 2 * amount)
    erc20_helpers.assert_address_balance(BUYER_1, 2 * amount)

    erc20_helpers.approve_for_bid(BUYER_1, amount)

    # First bid placed
    %{ end_prank = start_prank(ids.BUYER_1) %}
    place_bid(AUCTION_ID, Uint256(amount, 0))
    %{ end_prank() %}

    erc20_helpers.approve_for_bid(BUYER_1, 2 * amount)

    # Second bid placed
    %{ end_prank = start_prank(ids.BUYER_1) %}
    place_bid(AUCTION_ID, Uint256(2 * amount, 0))
    %{ end_prank() %}

    erc20_helpers.assert_address_balance(auction_contract_address, 2 * amount)
    erc20_helpers.assert_address_balance(BUYER_1, 0)

    return ()
end

@external
func test_placed_bid_not_enough_funds{
    syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr
}() -> ():
    alloc_locals
    let minimal_bid = Uint256(100, 0)
    let end_block = 100

    auction_helpers.create_auction(minimal_bid, end_block)
    %{ start_prank(ids.BUYER_1) %}
    %{ expect_revert(error_message="ERC20: insufficient allowance") %}
    place_bid(AUCTION_ID, minimal_bid)

    return ()
end

@external
func test_placed_bid_too_low{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
    ) -> ():
    alloc_locals
    let minimal_bid = Uint256(100, 0)
    let amount = 99
    let end_block = 100

    auction_helpers.prepare_topped_bid(BUYER_1, amount)
    auction_helpers.create_auction(minimal_bid, end_block)
    %{ start_prank(ids.BUYER_1) %}
    %{ expect_revert(error_message="New bid too low") %}
    place_bid(AUCTION_ID, Uint256(99, 0))

    return ()
end

@external
func test_placed_bid_lower_than_highest{
    syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr
}() -> ():
    alloc_locals
    let minimal_bid = Uint256(100, 0)
    let buyer_balance = 100
    let end_block = 100

    auction_helpers.prepare_topped_bid(BUYER_1, buyer_balance)
    auction_helpers.prepare_topped_bid(BUYER_2, buyer_balance)
    auction_helpers.create_auction(minimal_bid, end_block)
    %{ end_prank = start_prank(ids.BUYER_1) %}
    place_bid(AUCTION_ID, minimal_bid)
    %{ end_prank() %}

    %{ start_prank(ids.BUYER_2) %}
    %{ expect_revert(error_message="New bid too low") %}
    place_bid(AUCTION_ID, minimal_bid)

    return ()
end

@external
func test_placed_bid_auction_inactive{
    syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr
}() -> ():
    alloc_locals
    let minimal_bid = Uint256(100, 0)
    let amount = 100
    let end_block = 100

    auction_helpers.prepare_topped_bid(BUYER_1, amount)
    auction_helpers.create_auction(minimal_bid, end_block)

    %{ roll(ids.end_block + 1) %}

    %{ start_prank(ids.BUYER_1) %}
    %{ expect_revert(error_message="Auction is not active") %}
    place_bid(AUCTION_ID, minimal_bid)

    return ()
end
