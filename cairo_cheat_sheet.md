# Cairo Cheat Sheet

## Variables and constants

### Allocating and assigning a temporary variable

```cairo
tempvar x = 0 # Allocate and initialize
assert x = 5  # Assign x = 5
```

This value can be *revoked* due to jumps e.g. calling a helper function.

## Assertions

Memory in Cairo is immutable, `assert` on previously unallocated memory will
assign to this memory while `assert` on already allocated memory will perform
comparison and raise an assertion error.

```cairo
tempvar x
assert x = 5  # Assign x = 5
assert x = 7  # Raises assertion error
```

### Allocating and assigning a local variable

Locals will not be revoked due to jumps etc.

```cairo
alloc_locals  # Allocate memory for all following locals
local x = 0   # Define and assing
assert x = 5  # Assign x = 5
```

Locals can also be created directly from function result

```cairo
alloc_locals

let (local x) = my_function()
```

### Constants

```cairo
const MY_CONSTANT = 0
```

## Arrays

Arrays behave very much like they'd in C

```cairo
from starkware.cairo.common.alloc import alloc

let (my_array: felt*) = alloc()  # Not you don't specify the array size

assert my_array[0] = 0
assert my_array[1] = 2
```

It is necessary that you keep track of array size yourself. 
To pass array to a function you'd need to then provider both `my_array` pointer and `size` variable.

```
func function_accepting_array(array: felt*, size: felt):
    ...
end

funcion_accepting_array(my_array, 2)
```

When returning arrays from functions it is recommended you return both pointer to array
and a size of that array

```cairo
func function_returning_array() -> (arr: felt*, size: felt):
    ...
    return (arr=arr, size=size)
end
```

## Tuples

```cairo
# Create a tuple
local my_tuple : (felt, felt, felt) = (2, 4, 6) 

# Access second element
my_tuple[1]
```
 
## Structs

```cairo
# Define a struct

struct MyStruct:
    member first_member : felt
    member second_member : felt
end

# Create a struct instance
let struct_instance = MyStruct(first_member=0, second_member=1)

# Access struct values
struct_instance.first_member
```

## Functions

Use `func` keyword to define a function. A function block must always end with `end`
keyword and must always have a `return`.

### Defining functions

```cairo
# Function without return type
func my_func(arg1: felt, arg2: felt):
    return ()
end

# Function with return type
func my_func(arg1: felt, arg2: felt) -> (ret1: felt, ret2: felt):
    ...
    return (ret1=0, ret2=20)
end
```

### Calling functions

```cairo
my_func(0, 1)                       # Return value will be discarded
let res = my_func(0, 1)             # res will be a return value struct
let (res1, res2) = my_func(0, 1)    # Return value will be unpacked into res1, res2
```

## Recursion

Cairo generally doesn't have a concept of loops. Use recursion instead.

```cairo
# Computes the sum of the memory elements arr[0], arr[1], ..., arr[len(arr) - 1].
func array_sum(arr : felt*, size) -> (sum : felt):
    if size == 0:
        return (sum=0)
    end

    # size is not zero.
    let (sum_of_rest) = array_sum(arr=arr + 1, size=size - 1)
    return (sum=[arr] + sum_of_rest)
end
```

This is mostly equivalent to

```python
sum = 0 
for i in range(len(arr)):
    sum += arr[i]
```

## Builtins and implicit arguments

Cairo provides optimized "pointers" that can be used to perform certain expensive computations such as
calculating hashes. 

Builtins parameters should be defined inside curly braces `{}`, that way cairo will
implicitly manage passing them to functions.

### Common builtins

* `syscall_ptr` - invoke system calls like storage read and write
* `pedersen_ptr` - compute Pedersen hash function
* `range_check_ptr` - check if value is in range
* `ecdsa` - verify ECDSA signatures
* `bitwise` - perform bitwise operations on felt

```cairo
%builtins pedersen range_check ecdsa bitwise

from starkware.cairo.common.cairo_builtins import (
    BitwiseBuiltin,
    HashBuiltin,
    SignatureBuiltin,
)

func main{
    pedersen_ptr : HashBuiltin*,
    range_check_ptr,
    ecdsa_ptr : SignatureBuiltin*,
    bitwise_ptr : BitwiseBuiltin*,
}():
    # Code body here.
    return ()
end
```

## Storage variables

Contracts can define storage that can be read and modified.

Note `syscall_ptr`, `pedersen_ptr` and `range_check_ptr` implicit arguments

```cairo
%lang starknet
from starkware.cairo.common.cairo_builtins import HashBuiltin

@storage_var  # This annotation is necessary
func balance() -> (res : felt):
end

# Increases the balance by the given amount.
@external
func increase_balance{
    syscall_ptr : felt*,            # This is required to use .read() and .write()
    pedersen_ptr : HashBuiltin*,
    range_check_ptr,
}(amount : felt):
    let (res) = balance.read()
    balance.write(res + amount)
    return ()
end

# Returns the current balance.
@view
func get_balance{
    syscall_ptr : felt*,
    pedersen_ptr : HashBuiltin*,
    range_check_ptr,
}() -> (res : felt):
    let (res) = balance.read()
    return (res=res)
end
```

Storage can also work like a map - for example with pairs `user_address to balance`


```cairo
%lang starknet

from starkware.cairo.common.cairo_builtins import HashBuiltin
from starkware.cairo.common.math import assert_nn

@storage_var
func balance(user : felt) -> (res : felt):
end

# Returns the balance of the given user.
@view
func get_balance{
    syscall_ptr : felt*,            # This is required to use .read() and .write()
    pedersen_ptr : HashBuiltin*,    # This is required to compute memory address for the user
    range_check_ptr,                # This is required by the assert_nn
}(user : felt) -> (res : felt):
    let (res) = balance.read(user=user)
    return (res)
end

# Increases the balance of the user by the given amount.
@external
func increase_balance{
    syscall_ptr : felt*,
    pedersen_ptr : HashBuiltin*,
    range_check_ptr,
}(amount : felt):
    # Verify that the amount is positive.
    assert_nn(amount)

    # Obtain the address of the account contract.
    let (user) = get_caller_address()

    # Read and update its balance.
    let (res) = balance.read(user=user)
    balance.write(user, res + amount)
    return ()
end
```

## Syscalls

To use syscalls, `syscall_ptr` implicit argument need to be imported.

### Get_caller_address

Get an address of contract caller

```cairo
from starkware.starknet.common.syscalls import get_caller_address

let (caller_address) = get_caller_address()
```

### Get_tx_info

Get information about transactions used to invoke a function

```cairo
from starkware.starknet.common.syscalls import get_tx_info

func get_tx_max_fee{syscall_ptr : felt*}() -> (max_fee : felt):
    let (tx_info) = get_tx_info()

    ...
end
```

Available informations

```cairo
struct TxInfo:
    member version : felt

    # The account contract from which this transaction originates.
    member account_contract_address : felt

    # The max_fee field of the transaction.
    member max_fee : felt

    # The signature of the transaction.
    member signature_len : felt
    member signature : felt*

    # The hash of the transaction.
    member transaction_hash : felt

    # The identifier of the chain.
    member chain_id : felt
end
```

### Get_contract_address

Get the address of current contract

```cairo
from starkware.starknet.common.syscalls import (
    get_contract_address,
)

# ...

let (contract_address) = get_contract_address()
```

## Common library

Cairo has quite comprehensive common library. [See full list here](https://perama-v.github.io/cairo/cairo-common-library/)

Modules can be imported using `from starkware.cairo.common.MODULE import COMPONENT`

Some modules include:
* [math-cmp](https://perama-v.github.io/cairo/cairo-common-library/#math_cmp) for value comparisons
* [math](https://perama-v.github.io/cairo/cairo-common-library/#math) for mathematics operations
* [hash](https://perama-v.github.io/cairo/cairo-common-library/#hash) for computing Pedersen hash
