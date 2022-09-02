%lang starknet
from starkware.cairo.common.uint256 import Uint256

@event
func auction_created(
    auction_id : felt, asset_id : Uint256, min_bid_increment : Uint256, lifetime : felt
):
end

@event
func bid_placed(auction_id : felt, amount : Uint256):
end

@event
func auction_finalized(auction_id : felt):
end
