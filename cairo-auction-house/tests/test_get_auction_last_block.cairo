%lang starknet

from starkware.cairo.common.cairo_builtins import HashBuiltin
from starkware.starknet.common.syscalls import (
    get_caller_address,
    get_block_number,
    get_contract_address,
)
from starkware.cairo.common.uint256 import Uint256

from openzeppelin.token.erc721.IERC721 import IERC721

from src.main import get_auction_last_block
from src.storage import auction_last_block

from tests.helpers.erc721 import erc721_helpers
from tests.helpers.data import data_helpers
from tests.helpers.erc20 import erc20_helpers
from tests.helpers.constants import SELLER, AUCTION_ID
from tests.helpers.auction import auction_helpers

@external
func test_get_last_block_not_initialized{
    syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr
}() -> ():
    %{ expect_revert(error_message="Last block was not initialized") %}
    get_auction_last_block(2137)

    return ()
end

@external
func test_existing_last_block{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
    ) -> ():
    alloc_locals
    let expected_last_block = 2137
    auction_last_block.write(AUCTION_ID, expected_last_block)

    let (last_block) = get_auction_last_block(AUCTION_ID)

    assert expected_last_block = last_block

    return ()
end
