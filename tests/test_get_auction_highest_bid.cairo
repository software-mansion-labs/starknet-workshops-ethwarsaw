%lang starknet

from starkware.cairo.common.cairo_builtins import HashBuiltin
from starkware.starknet.common.syscalls import (
    get_caller_address,
    get_block_number,
    get_contract_address,
)
from starkware.cairo.common.uint256 import Uint256

from openzeppelin.token.erc721.IERC721 import IERC721

from src.main import get_auction_highest_bid
from src.data import Bid
from src.storage import auction_highest_bid

from tests.helpers.erc721 import erc721_helpers
from tests.helpers.data import data_helpers
from tests.helpers.erc20 import erc20_helpers
from tests.helpers.constants import SELLER, AUCTION_ID
from tests.helpers.auction import auction_helpers

@external
func test_get_bid_when_no_bid_exist{
    syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr
}() -> () {
    %{ expect_revert(error_message="Bid was not initialized") %}
    get_auction_highest_bid(2137);

    return ();
}

@external
func test_existing_bid{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}() -> () {
    alloc_locals;
    let amount = Uint256(100, 0);
    let account = 'account';
    auction_highest_bid.write(AUCTION_ID, Bid(amount, account));

    let (highest_bid) = get_auction_highest_bid(AUCTION_ID);

    assert amount = highest_bid.amount;
    assert account = highest_bid.address;

    return ();
}
