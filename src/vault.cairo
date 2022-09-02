%lang starknet

from starkware.cairo.common.cairo_builtins import HashBuiltin
from starkware.cairo.common.uint256 import Uint256
from starkware.starknet.common.syscalls import get_contract_address, get_caller_address
from openzeppelin.token.erc721.IERC721 import IERC721
from openzeppelin.token.erc20.IERC20 import IERC20
from src.data import Bid

namespace vault:
    func deposit_asset{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
        erc721_address : felt, asset_id : Uint256, source : felt
    ):
        let (current_address) = get_contract_address()

        IERC721.transferFrom(
            contract_address=erc721_address, from_=source, to=current_address, tokenId=asset_id
        )

        return ()
    end

    func transfer_asset{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
        erc721_address : felt, asset_id : Uint256, target : felt
    ):
        let (address) = get_contract_address()

        IERC721.transferFrom(
            contract_address=erc721_address, from_=address, to=target, tokenId=asset_id
        )

        return ()
    end

    func deposit_bid{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
        erc20_address : felt, bid : Bid
    ):
        let (auction_contract_address) = get_contract_address()

        let low = bid.amount.low
        let high = bid.amount.high
        let address = bid.address
        let (result) = IERC20.transferFrom(
            contract_address=erc20_address,
            sender=bid.address,
            recipient=auction_contract_address,
            amount=bid.amount,
        )

        return ()
    end

    # Transfer tokens sent with a bid to target address.
    # In practice it is either seller (as payment for the asset) or the bidder (after a higher bid is placed).
    func transfer_bid{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
        erc20_address : felt, bid : Bid, target_address : felt
    ):
        let (address) = get_contract_address()

        let (result) = IERC20.transfer(
            contract_address=erc20_address, recipient=target_address, amount=bid.amount
        )

        return ()
    end
end
