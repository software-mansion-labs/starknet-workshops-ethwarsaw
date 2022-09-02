%lang starknet

from starkware.cairo.common.uint256 import Uint256
from starkware.cairo.common.math import assert_not_zero

struct Bid:
    member amount : Uint256
    member address : felt
end

struct AuctionData:
    member seller : felt
    member asset_id : Uint256
    member min_bid_increment : Uint256
    member erc20_address : felt
    member erc721_address : felt
end

func is_bid_initialized(bid : Bid) -> (result : felt):
    # Initialized bid can't have address == 0
    if bid.address == 0:
        return (0)
    else:
        return (1)
    end
end
