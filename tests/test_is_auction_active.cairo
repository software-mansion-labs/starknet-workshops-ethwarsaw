%lang starknet

from starkware.cairo.common.cairo_builtins import HashBuiltin
from starkware.starknet.common.syscalls import (
    get_caller_address,
    get_block_number,
    get_contract_address,
)
from starkware.cairo.common.uint256 import Uint256

from openzeppelin.token.erc721.IERC721 import IERC721

from src.main import is_auction_active
from src.storage import auction_last_block

from tests.helpers.erc721 import erc721_helpers
from tests.helpers.data import data_helpers
from tests.helpers.erc20 import erc20_helpers
from tests.helpers.constants import SELLER, AUCTION_ID
from tests.helpers.auction import auction_helpers

@external
func __setup__() {
    erc20_helpers.deploy_contract();
    erc721_helpers.deploy_contract();
    return ();
}

@external
func test_auction_does_not_exist{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    ) -> () {
    %{ expect_revert(error_message="Last block was not initialized") %}
    is_auction_active(2137);

    return ();
}

@external
func test_auction_is_active{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}() -> (
    ) {
    alloc_locals;
    let minimal_bid = Uint256(100, 0);
    let end_block = 100;

    auction_helpers.create_auction(minimal_bid, end_block);

    %{ roll(ids.end_block - 1) %}
    let (is_active) = is_auction_active(AUCTION_ID);
    assert 1 = is_active;

    // Last block when auction is active
    %{ roll(ids.end_block) %}
    let (is_active) = is_auction_active(AUCTION_ID);
    assert 1 = is_active;

    %{ roll(ids.end_block + 1) %}
    let (is_active) = is_auction_active(AUCTION_ID);
    assert 0 = is_active;

    return ();
}
