%lang starknet

from starkware.cairo.common.cairo_builtins import HashBuiltin
from starkware.starknet.common.syscalls import (
    get_caller_address,
    get_block_number,
    get_contract_address,
)
from starkware.cairo.common.uint256 import Uint256

from openzeppelin.token.erc721.IERC721 import IERC721

from src.main import get_auction
from src.data import AuctionData
from src.storage import auctions

from tests.helpers.erc721 import erc721_helpers
from tests.helpers.data import data_helpers
from tests.helpers.erc20 import erc20_helpers
from tests.helpers.constants import SELLER, AUCTION_ID
from tests.helpers.auction import auction_helpers

@external
func test_get_non_existing_auction{
    syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr
}() -> ():
    %{ expect_revert(error_message="Auction was not initalized") %}
    get_auction(2137)

    return ()
end

@external
func test_get_existing_auction{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
    ) -> ():
    alloc_locals
    let token_id = Uint256(0, 1)

    let auction = AuctionData(
        seller=SELLER,
        asset_id=token_id,
        min_bid_increment=Uint256(100, 0),
        erc20_address='erc20_address',
        erc721_address='erc721_address',
    )
    auctions.write(AUCTION_ID, auction)

    let (returned_auction) = get_auction(AUCTION_ID)

    data_helpers.assert_auctions_equal(auction, returned_auction)

    return ()
end
