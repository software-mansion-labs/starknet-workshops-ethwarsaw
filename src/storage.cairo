%lang starknet
from src.data import AuctionData, Bid

@storage_var
func auctions(auction_id : felt) -> (auction : AuctionData):
end

@storage_var
func finalized_auctions(auction_id : felt) -> (is_closed : felt):
end

@storage_var
func auction_highest_bid(auction_id : felt) -> (highest_bid : Bid):
end

# Last block when sale is active
@storage_var
func auction_last_block(auction_id : felt) -> (end_block : felt):
end
