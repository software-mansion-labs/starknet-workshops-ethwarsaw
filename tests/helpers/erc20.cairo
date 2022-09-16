%lang starknet

from starkware.cairo.common.math import split_felt, unsigned_div_rem
from starkware.starknet.common.syscalls import get_caller_address
from starkware.starknet.common.syscalls import get_contract_address
from starkware.cairo.common.uint256 import Uint256

from openzeppelin.token.erc20.IERC20 import IERC20

const ADMIN = 'erc20_admin';

namespace erc20_helpers {
    func assert_address_balance{syscall_ptr: felt*, range_check_ptr}(address: felt, balance: felt) {
        let (erc20_address) = get_address();
        let (state) = IERC20.balanceOf(contract_address=erc20_address, account=address);
        assert balance = state.low;
        assert 0 = state.high;
        return ();
    }

    func assert_balance{syscall_ptr: felt*}(amount: felt) {
        let (address) = get_caller_address();
        erc20_helpers.assert_address_balance(address, amount);
        return ();
    }

    // Approves control over an amount of tokens for our contract for bidding
    func approve_for_bid{syscall_ptr: felt*, range_check_ptr}(address: felt, amount: felt) {
        alloc_locals;
        let (erc20_address) = get_address();
        let (contract_address) = get_contract_address();
        %{ end_prank = start_prank(ids.address, ids.erc20_address) %}
        IERC20.approve(
            contract_address=erc20_address, spender=contract_address, amount=Uint256(amount, 0)
        );
        %{ end_prank() %}
        return ();
    }

    func top_up_address{syscall_ptr: felt*, range_check_ptr}(address: felt, amount: felt) {
        alloc_locals;
        let (local erc20_address) = get_address();

        %{ stop = start_prank(ids.ADMIN, ids.erc20_address) %}
        IERC20.transfer(
            contract_address=erc20_address, recipient=address, amount=Uint256(amount, 0)
        );
        %{ stop() %}
        return ();
    }

    func top_up{syscall_ptr: felt*, range_check_ptr}(amount: felt) {
        let (address) = get_caller_address();
        erc20_helpers.top_up_address(address, amount);
        return ();
    }

    // Deploys ERC20 contract using deploy_contract cheatcode.
    // This takes a lot of time and should be done just once in __setup__ hook.
    // Deployed contract's address is stored in context available through hints.
    func deploy_contract() {
        %{
            context.erc20_address = deploy_contract(
                "./lib/cairo_contracts/src/openzeppelin/token/erc20/presets/ERC20.cairo",
                [0, 0, 0, 10**20, 10**20, ids.ADMIN],
            ).contract_address
        %}
        return ();
    }

    // Returns address of contract deployed with deploy_contract
    func get_address() -> (address: felt) {
        tempvar address;
        %{ ids.address = context.erc20_address %}
        return (address,);
    }
}
