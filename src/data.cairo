%lang starknet

from starkware.cairo.common.uint256 import Uint256
from starkware.cairo.common.math import assert_not_zero

struct Bid {
    amount: Uint256,
    address: felt,
}

struct AuctionData {
    seller: felt,
    asset_id: Uint256,
    min_bid_increment: Uint256,
    erc20_address: felt,
    erc721_address: felt,
}

func is_bid_initialized(bid: Bid) -> (result: felt) {
    // Initialized bid can't have address == 0
    if (bid.address == 0) {
        return (0,);
    } else {
        return (1,);
    }
}
