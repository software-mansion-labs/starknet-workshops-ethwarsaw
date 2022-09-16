%lang starknet

from starkware.cairo.common.math import split_felt, unsigned_div_rem
from starkware.starknet.common.syscalls import get_caller_address
from starkware.starknet.common.syscalls import get_contract_address
from starkware.cairo.common.cairo_builtins import HashBuiltin
from starkware.cairo.common.uint256 import Uint256

from openzeppelin.token.erc20.IERC20 import IERC20

from src.main import place_bid
from src.storage import auctions, auction_last_block
from src.data import AuctionData
from src.vault import vault

from tests.helpers.erc20 import erc20_helpers
from tests.helpers.erc721 import erc721_helpers
from tests.helpers.constants import SELLER, AUCTION_ID

namespace auction_helpers {
    // Tops up user account and places a bid, ensuring right balances at the end
    func topped_bid{syscall_ptr: felt*, range_check_ptr, pedersen_ptr: HashBuiltin*}(
        auction_id: felt, user_address: felt, amount: felt
    ) {
        alloc_locals;
        let (auction_contract_address) = get_contract_address();

        prepare_topped_bid(user_address, amount);

        %{ end_prank = start_prank(ids.user_address) %}
        place_bid(auction_id, Uint256(amount, 0));
        %{ end_prank() %}

        erc20_helpers.assert_address_balance(auction_contract_address, amount);
        erc20_helpers.assert_address_balance(user_address, 0);

        return ();
    }

    func create_auction{syscall_ptr: felt*, range_check_ptr, pedersen_ptr: HashBuiltin*}(
        min_bid_increment: Uint256, end_block: felt
    ) {
        alloc_locals;
        let token_id = Uint256(0, 1);
        let (local erc20_address) = erc20_helpers.get_address();
        let (local erc721_address) = erc721_helpers.get_address();

        let auction = AuctionData(
            seller=SELLER,
            asset_id=token_id,
            min_bid_increment=min_bid_increment,
            erc20_address=erc20_address,
            erc721_address=erc721_address,
        );

        erc721_helpers.mint(SELLER, token_id);

        %{ end_prank = start_prank(ids.SELLER, ids.erc721_address) %}
        erc721_helpers.approve_for_auction(token_id);
        %{ end_prank() %}

        auctions.write(AUCTION_ID, auction);
        auction_last_block.write(AUCTION_ID, end_block);

        vault.deposit_asset(erc721_address, token_id, SELLER);

        return ();
    }

    func prepare_topped_bid{syscall_ptr: felt*, range_check_ptr, pedersen_ptr: HashBuiltin*}(
        user_address: felt, amount: felt
    ) {
        erc20_helpers.top_up_address(user_address, amount);
        erc20_helpers.assert_address_balance(user_address, amount);
        erc20_helpers.approve_for_bid(user_address, amount);
        return ();
    }
}
