# foundry-abi

Contains automatically-generated Rust bindings from Solidity ABI.

Additional bindings can be generated by doing the following:

1. add an ABI file in the [`abi` directory](./abi/), using the [ethers-js ABI formats](https://docs.ethers.org/v5/api/utils/abi/formats);
2. update the [build script](./build.rs)'s `MultiAbigen::new` call;
3. build the crate once with `cargo build -p foundry-abi`, generating the bindings for the first time;
4. export the newly-generated bindings at the root of the crate, in [`lib.rs`](./src/lib.rs).

New cheatcodes can be added by doing the following:

1. add its Solidity definition(s) in [`HEVM.sol`](./abi/HEVM.sol), bindings should regenerate automatically;
2. implement it in [`foundry-evm`](../evm/src/executor/inspector/cheatcodes/);
3. update the [`Vm.sol`](../../testdata/cheats/Vm.sol) test interface;
4. add tests in [`testdata`](../../testdata/cheats/);
5. open a PR to [`forge-std`](https://github.com/foundry-rs/forge-std) to add it to the `Vm` interface.
