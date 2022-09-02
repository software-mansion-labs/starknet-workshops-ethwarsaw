%lang starknet

from starkware.cairo.common.cairo_builtins import HashBuiltin
from starkware.starknet.common.syscalls import (
    get_caller_address,
    get_block_number,
    get_contract_address,
)
from starkware.cairo.common.uint256 import Uint256

from openzeppelin.token.erc721.IERC721 import IERC721

from src.main import create_auction, AuctionData, auctions, auction_last_block

from tests.helpers.erc721 import erc721_helpers
from tests.helpers.data import data_helpers
from tests.helpers.erc20 import erc20_helpers
from tests.helpers.constants import SELLER, AUCTION_ID

@external
func __setup__():
    erc20_helpers.deploy_contract()
    erc721_helpers.deploy_contract()
    return ()
end

@external
func test_auction_created{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}() -> (
    ):
    alloc_locals
    let (auction_contract_address) = get_contract_address()
    let (current_block_number) = get_block_number()
    let auction_lifetime = 100  # in blocks
    let token_id = Uint256(0, 1)
    let (erc20_address) = erc20_helpers.get_address()
    let (local erc721_address) = erc721_helpers.get_address()
    let expected_auction = AuctionData(
        seller=SELLER,
        asset_id=token_id,
        min_bid_increment=Uint256(100, 0),
        erc20_address=erc20_address,
        erc721_address=erc721_address,
    )
    erc721_helpers.mint(SELLER, token_id)

    %{ end_prank = start_prank(ids.SELLER, ids.erc721_address) %}
    erc721_helpers.approve_for_auction(token_id)
    %{ end_prank() %}

    %{ expect_events({"name": "auction_created", "data": [ids.AUCTION_ID, 0, 1, 100, 0, ids.auction_lifetime]}) %}

    %{ end_prank = start_prank(ids.SELLER) %}
    create_auction(
        auction_id=AUCTION_ID,
        asset_id=expected_auction.asset_id,
        min_bid_increment=expected_auction.min_bid_increment,
        erc20_address=expected_auction.erc20_address,
        erc721_address=expected_auction.erc721_address,
        lifetime=auction_lifetime,
    )
    %{ end_prank() %}

    let (saved_auction) = auctions.read(AUCTION_ID)
    data_helpers.assert_auctions_equal(expected_auction, saved_auction)

    erc721_helpers.assert_has_token(auction_contract_address, token_id)

    let (end_block) = auction_last_block.read(AUCTION_ID)
    assert auction_lifetime + current_block_number = end_block

    return ()
end

@external
func test_create_auction_already_exists{
    syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr
}() -> ():
    alloc_locals

    let token_id = Uint256(0, 1)
    let (local erc20_address) = erc20_helpers.get_address()
    let (local erc721_address) = erc721_helpers.get_address()

    erc721_helpers.mint(SELLER, token_id)

    %{ end_prank = start_prank(ids.SELLER, ids.erc721_address) %}
    erc721_helpers.approve_for_auction(token_id)
    %{ end_prank() %}

    %{ start_prank(ids.SELLER) %}
    create_auction(
        auction_id=AUCTION_ID,
        asset_id=Uint256(0, 1),
        min_bid_increment=Uint256(100, 0),
        erc20_address=erc20_address,
        erc721_address=erc721_address,
        lifetime=100,
    )

    %{ expect_revert(error_message="Auction 27432142756212590 already exists!") %}
    create_auction(
        auction_id=AUCTION_ID,
        asset_id=Uint256(0, 2),
        min_bid_increment=Uint256(101, 0),
        erc20_address=erc20_address,
        erc721_address=erc721_address,
        lifetime=100,
    )

    return ()
end

@external
func test_create_auction_incorrect_erc_address{
    syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr
}() -> ():
    alloc_locals

    let token_id = Uint256(0, 1)
    let erc20_address = 0
    let (local erc721_address) = erc721_helpers.get_address()

    erc721_helpers.mint(SELLER, token_id)

    %{ end_prank = start_prank(ids.SELLER, ids.erc721_address) %}
    erc721_helpers.approve_for_auction(token_id)
    %{ end_prank() %}

    %{ start_prank(ids.SELLER) %}
    %{ expect_revert(error_message="Invalid address 0") %}
    create_auction(
        auction_id=AUCTION_ID,
        asset_id=Uint256(0, 1),
        min_bid_increment=Uint256(100, 0),
        erc20_address=erc20_address,
        erc721_address=erc721_address,
        lifetime=100,
    )

    return ()
end

@external
func test_create_auction_incorrect_bid_increment{
    syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr
}() -> ():
    alloc_locals

    let token_id = Uint256(0, 1)
    let (local erc20_address) = erc20_helpers.get_address()
    let (local erc721_address) = erc721_helpers.get_address()

    erc721_helpers.mint(SELLER, token_id)

    %{ end_prank = start_prank(ids.SELLER, ids.erc721_address) %}
    erc721_helpers.approve_for_auction(token_id)
    %{ end_prank() %}

    %{ start_prank(ids.SELLER) %}
    %{ expect_revert(error_message="Invalid minimal value for bid, has to be >= 0") %}
    create_auction(
        auction_id=AUCTION_ID,
        asset_id=Uint256(0, 1),
        min_bid_increment=Uint256(0, 0),
        erc20_address=erc20_address,
        erc721_address=erc721_address,
        lifetime=100,
    )

    return ()
end

@external
func test_create_auction_negative_lifetime{
    syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr
}() -> ():
    alloc_locals

    let token_id = Uint256(0, 1)
    let (local erc20_address) = erc20_helpers.get_address()
    let (local erc721_address) = erc721_helpers.get_address()

    erc721_helpers.mint(SELLER, token_id)

    %{ end_prank = start_prank(ids.SELLER, ids.erc721_address) %}
    erc721_helpers.approve_for_auction(token_id)
    %{ end_prank() %}

    %{ start_prank(ids.SELLER) %}
    %{ expect_revert(error_message="Invalid lifetime, has to be > 0") %}
    create_auction(
        auction_id=AUCTION_ID,
        asset_id=Uint256(0, 1),
        min_bid_increment=Uint256(100, 0),
        erc20_address=erc20_address,
        erc721_address=erc721_address,
        lifetime=-1,
    )

    return ()
end

@external
func test_create_auction_asset_does_not_exist{
    syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr
}() -> ():
    alloc_locals

    let token_id = Uint256(0, 1)
    let (local erc20_address) = erc20_helpers.get_address()
    let (local erc721_address) = erc721_helpers.get_address()

    %{ start_prank(ids.SELLER) %}
    %{ expect_revert(error_message="ERC721: token id does not exist") %}
    create_auction(
        auction_id=AUCTION_ID,
        asset_id=Uint256(0, 1),
        min_bid_increment=Uint256(0, 100),
        erc20_address=erc20_address,
        erc721_address=erc721_address,
        lifetime=100,
    )

    return ()
end

@external
func test_create_auction_token_not_approved{
    syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr
}() -> ():
    alloc_locals

    let token_id = Uint256(0, 1)
    let (local erc20_address) = erc20_helpers.get_address()
    let (local erc721_address) = erc721_helpers.get_address()

    erc721_helpers.mint(SELLER, token_id)

    %{ start_prank(ids.SELLER) %}
    %{ expect_revert(error_message="ERC721: either is not approved or the caller is the zero address") %}
    create_auction(
        auction_id=AUCTION_ID,
        asset_id=Uint256(0, 1),
        min_bid_increment=Uint256(0, 100),
        erc20_address=erc20_address,
        erc721_address=erc721_address,
        lifetime=100,
    )

    return ()
end

@external
func test_create_auction_not_an_owner{
    syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr
}() -> ():
    alloc_locals

    let token_id = Uint256(0, 1)
    let (local erc20_address) = erc20_helpers.get_address()
    let (local erc721_address) = erc721_helpers.get_address()

    erc721_helpers.mint(SELLER, token_id)

    %{ end_prank = start_prank(ids.SELLER, ids.erc721_address) %}
    erc721_helpers.approve_for_auction(token_id)
    %{ end_prank() %}

    %{ start_prank(123) %}
    %{ expect_revert(error_message="ERC721: transfer from incorrect owner") %}
    create_auction(
        auction_id=AUCTION_ID,
        asset_id=Uint256(0, 1),
        min_bid_increment=Uint256(100, 0),
        erc20_address=erc20_address,
        erc721_address=erc721_address,
        lifetime=100,
    )

    return ()
end
