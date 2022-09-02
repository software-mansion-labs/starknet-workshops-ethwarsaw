%lang starknet
from starkware.cairo.common.math import assert_lt
from starkware.cairo.common.math_cmp import is_le
from starkware.cairo.common.cairo_builtins import HashBuiltin
from starkware.cairo.common.hash import hash2
from starkware.cairo.common.uint256 import Uint256, uint256_le, uint256_add
from starkware.starknet.common.syscalls import (
    get_caller_address,
    get_block_number,
    get_contract_address,
)

from openzeppelin.security.safemath.library import SafeUint256
from openzeppelin.token.erc20.IERC20 import IERC20

from src.data import AuctionData, Bid, is_bid_initialized
from src.constants import AUCTION_PROLONGATION_ON_BID
from src.vault import vault
from src.events import auction_created, bid_placed, auction_finalized
from src.assertions import (
    assert_auction_does_not_exist,
    assert_address,
    assert_min_bid_increment,
    assert_lifetime,
    assert_bid_initialized,
    assert_auction_initialized,
    assert_last_block_initialized,
    assert_auction_not_finalized,
)
from src.storage import auctions, finalized_auctions, auction_highest_bid, auction_last_block


##### EXERCISE 0 #####

# Implement getters:
# - get_auction(auction_id : felt) -> (auction : AuctionData)
# - get_auction_highest_bid(auction_id : felt) -> (highest_bid : Bid)
# - get_auction_last_block(auction_id : felt) -> (end_block : felt)
#
# - Remember about @view decorator
# - Check cairo_cheat_sheet.md for reference
#
# To test it, run:
# protostar test tests/test_get_*.cairo



##### EXERCISE 1 #####

# Implement content of is_auction_active method
# It should return 1 if current_block <= end block of an auction
# and 0 otherwise.
#
# - Check syscalls section of cairo_cheat_sheet.md
#   for how to get current block number.
#
# To test it, run:
# protostar test tests/test_is_auction_active.cairo

func is_auction_active{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
    auction_id : felt
) -> (is_active: felt):
    alloc_locals

    # Write your solution below

    return (0)
    # ^ Remember to change this!
end

func assert_auction_active{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
    auction_id : felt
):
    let (active) = is_auction_active(auction_id)

    with_attr error_message("Auction is not active"):
        assert active = 1
    end

    return ()
end

func assert_auction_not_active{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
    auction_id : felt
):
    let (active) = is_auction_active(auction_id)

    with_attr error_message("Auction is still active"):
        assert active = 0
    end

    return ()
end

##### EXERCISE 2 #####

# Implement content of the create_auction function
# - It should create new AuctionData object with provided
#   information, and save it to auctions storage
# - It should calculate the end block of the auction, based on
#   current block number and auction lifetime
# - Then it should use vault, to deposit seller's asset in the
#   contract
# - And in the end, emit auction_created event. (see events.cairo file, and cheat_sheet)
#
# To test it, run:
# protostar test tests/test_create_auction.cairo

@external
func create_auction{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
    auction_id : felt,
    asset_id : Uint256,
    min_bid_increment : Uint256,
    erc20_address : felt,
    erc721_address : felt,
    lifetime : felt,
) -> (auction_id : felt):
    alloc_locals

    assert_auction_does_not_exist(auction_id)
    assert_address(erc20_address)
    assert_address(erc721_address)
    assert_min_bid_increment(min_bid_increment)
    assert_lifetime(lifetime)

    ### Place your implementation below

    return (auction_id)
end

func verify_outbid{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
    auction_id : felt, old_bid : Bid, new_bid : Bid
):
    alloc_locals  # explain why it is needed
    let (auction) = get_auction(auction_id)
    let (min_bid) = SafeUint256.add(old_bid.amount, auction.min_bid_increment)

    let (higher_than_minimum) = uint256_le(min_bid, new_bid.amount)

    with_attr error_message("New bid too low"):
        assert higher_than_minimum = 1
    end

    return ()
end

func prolong_auction_on_end{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
    auction_id
):
    alloc_locals

    let (local current_block) = get_block_number()
    let (local end_block) = get_auction_last_block(auction_id)

    local diff = end_block - current_block

    let (should_prolong) = is_le(diff, AUCTION_PROLONGATION_ON_BID)
    if should_prolong == 1:
        let new_last_block = end_block + AUCTION_PROLONGATION_ON_BID
        auction_last_block.write(auction_id, new_last_block)
        tempvar syscall_ptr = syscall_ptr
        tempvar pedersen_ptr = pedersen_ptr
        tempvar range_check_ptr = range_check_ptr
    else:
        tempvar syscall_ptr = syscall_ptr
        tempvar pedersen_ptr = pedersen_ptr
        tempvar range_check_ptr = range_check_ptr
    end

    return ()
end

##### EXERCISE 3 #####

# Implement logic of placing a bid on an auction. It should
# - Get old_bid object, and create new_bid object
# - Verify if the outbid is valid
# - Write the new bid to the storage.
# - Prolong auction end time if needed (see above function)
# - check whether previous bid exists -> if so, return previous bid to the bidder (use vault for that)
# - deposit bid from the new bidder in the contract
# - at the end, emit the bid_place event
#
# To test it, run:
# protostar test tests/test_place_bid.cairo

@external
func place_bid{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
    auction_id : felt, amount : Uint256
):
    alloc_locals

    assert_auction_active(auction_id)

    # Write your solution below

    return ()
end

##### EXERCISE 4 #####

# Implement logic of finilizing the auction
# It should:
# - write to finalized_auctions storage, that the auction was finalized
# - get highest bid and verify that it was initialized - i.e. that anyone has bidded on this auction
# - If yes, send the money to the seller and the asset to the buyer
# - If not, return the asset to the seller
# - At the end, emit the auction_finalized event.
#
# To test it, run:
# protostar test tests/test_finalize_auction.cairo

@external
func finalize_auction{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
    auction_id : felt
):
    alloc_locals

    assert_auction_not_active(auction_id)
    assert_auction_not_finalized(auction_id)

    # Write your solution below

    return ()
end
