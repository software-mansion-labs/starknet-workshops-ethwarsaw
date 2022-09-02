%lang starknet
from starkware.cairo.common.cairo_builtins import HashBuiltin
from starkware.cairo.common.math import assert_nn, assert_not_zero
from starkware.cairo.common.uint256 import Uint256, uint256_lt

from src.storage import auctions, finalized_auctions, auction_highest_bid, auction_last_block
from src.data import AuctionData, Bid, is_bid_initialized

func assert_auction_does_not_exist{
    syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr
}(auction_id):
    alloc_locals

    with_attr error_message("Auction {auction_id} already exists!"):
        let (existing_auction) = auctions.read(auction_id)
        assert existing_auction.seller = 0
        assert existing_auction.asset_id = Uint256(0, 0)
    end

    return ()
end

func assert_address{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(address):
    with_attr error_message("Invalid address {address}"):
        assert_not_zero(address)
    end

    return ()
end

func assert_min_bid_increment{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
    min_bid_increment : Uint256
):
    with_attr error_message("Invalid minimal value for bid, has to be >= 0"):
        let (value) = uint256_lt(Uint256(1, 0), min_bid_increment)
        assert value = 1
    end

    return ()
end

func assert_lifetime{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(lifetime):
    with_attr error_message("Invalid lifetime, has to be > 0"):
        assert_not_zero(lifetime)
        assert_nn(lifetime)
    end

    return ()
end

func assert_auction_initialized(auction : AuctionData):
    with_attr error_message("Auction was not initalized"):
        assert_not_zero(auction.seller)
    end
    return ()
end

func assert_bid_initialized(bid : Bid):
    let (initialized) = is_bid_initialized(bid)
    with_attr error_message("Bid was not initialized"):
        assert initialized = 1
    end
    return ()
end

func assert_last_block_initialized(end_block : felt):
    with_attr error_message("Last block was not initialized"):
        assert_not_zero(end_block)
    end
    return ()
end

func assert_auction_not_finalized{
    syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr
}(auction_id):
    let (is_finalized) = finalized_auctions.read(auction_id)
    with_attr error_message("Auction is already finalized"):
        assert is_finalized = 0
    end
    return ()
end
