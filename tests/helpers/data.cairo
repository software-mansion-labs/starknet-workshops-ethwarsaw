%lang starknet

from starkware.cairo.common.math import split_felt, unsigned_div_rem
from starkware.starknet.common.syscalls import get_caller_address
from starkware.cairo.common.uint256 import Uint256

from openzeppelin.token.erc721.IERC721 import IERC721

from src.data import AuctionData

namespace data_helpers {
    func assert_auctions_equal(auction_a: AuctionData, auction_b: AuctionData) {
        with_attr error_message("Auctions are not the same") {
            assert auction_a.seller = auction_b.seller;
            assert auction_a.asset_id = auction_b.asset_id;
            assert auction_a.min_bid_increment = auction_b.min_bid_increment;
            assert auction_a.erc20_address = auction_b.erc20_address;
            assert auction_a.erc721_address = auction_b.erc721_address;
        }
        return ();
    }
}
