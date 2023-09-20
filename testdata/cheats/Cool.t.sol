// SPDX-License-Identifier: Unlicense
pragma solidity 0.8.18;

import "../lib/ds-test/src/test.sol";
import "./Vm.sol";

contract CoolTest is DSTest {
    Vm constant vm = Vm(HEVM_ADDRESS);
    uint256 public slot0;
    uint256 public slot1 = 1;

    function testCool_SLOAD_normal() public {
        uint256 startGas;
        uint256 endGas;
        uint256 beforeCoolGas;
        uint256 noCoolGas;

        startGas = gasleft();
        uint256 val = slot0;
        endGas = gasleft();
        beforeCoolGas = startGas - endGas;

        startGas = gasleft();
        uint256 val2 = slot0;
        endGas = gasleft();
        noCoolGas = startGas - endGas;

        assertEq(val, val2);
        assertGt(beforeCoolGas, noCoolGas);
    }

    function testCool_SLOAD() public {
        uint256 startGas;
        uint256 endGas;
        uint256 beforeCoolGas;
        uint256 afterCoolGas;
        uint256 warmGas;
        uint256 secondCoolGas;

        startGas = gasleft();
        uint256 val = slot0;
        endGas = gasleft();
        beforeCoolGas = startGas - endGas;

        vm.cool(address(this));

        startGas = gasleft();
        uint256 val2 = slot0;
        endGas = gasleft();
        afterCoolGas = startGas - endGas;

        assertEq(val, val2);
        assertEq(beforeCoolGas, afterCoolGas);
        assertEq(beforeCoolGas, 2100 + 13);

        startGas = gasleft();
        uint256 val3 = slot0;
        endGas = gasleft();
        warmGas = startGas - endGas;

        assertEq(val2, val3);
        assertGt(beforeCoolGas, warmGas);
        assertEq(warmGas, 100 + 13);

        // cool again to see if same resut
        vm.cool(address(this));

        startGas = gasleft();
        uint256 val4 = slot0;
        endGas = gasleft();
        secondCoolGas = startGas - endGas;

        assertEq(val, val4);
        assertEq(beforeCoolGas, secondCoolGas);
        assertEq(beforeCoolGas, 2100 + 13);
    }

    // check if slot value is preserved
    function testCool_SSTORE_check_slot_value() public {
        slot0 = 2;
        assertEq(slot0, 2);
        assertEq(slot1, 1);

        vm.cool(address(this));
        assertEq(slot0, 2);
        assertEq(slot1, 1);

        slot0 = 3;
        assertEq(slot0, 3);
        assertEq(slot1, 1);

        vm.cool(address(this));
        assertEq(slot0, 3);
        assertEq(slot1, 1);

        slot0 = 8;
        slot1 = 9;

        vm.cool(address(this));
        assertEq(slot0, 8);
        assertEq(slot1, 9);
    }

    function testCool_SSTORE_nonzero_to_nonzero() public {
        uint256 startGas;
        uint256 endGas;
        uint256 beforeCoolGas;
        uint256 afterCoolGas;
        uint256 warmGas;

        // start as non-zero
        startGas = gasleft();
        slot1 = 2; // 5k gas
        endGas = gasleft();
        beforeCoolGas = startGas - endGas;
        assertEq(slot1, 2);
        assertEq(beforeCoolGas, 2900 + 2100 + 13);

        // cool and set to same value
        vm.cool(address(this));

        startGas = gasleft();
        slot1 = 2; // 5k gas
        endGas = gasleft();
        afterCoolGas = startGas - endGas;
        assertEq(slot1, 2);
        assertEq(afterCoolGas, 100 + 2100 + 13);

        // cool and set from non-zero to another non-zero
        vm.cool(address(this));

        startGas = gasleft();
        slot1 = 3; // 5k gas
        endGas = gasleft();
        afterCoolGas = startGas - endGas;
        assertEq(slot1, 3);
        assertEq(afterCoolGas, 2900 + 2100 + 13);

        // don't cool and set non-zero to another non-zero
        startGas = gasleft();
        slot1 = 3; // 100 gas
        endGas = gasleft();
        warmGas = startGas - endGas;
        assertEq(slot1, 3);
        assertGt(afterCoolGas, warmGas);
        assertEq(warmGas, 100 + 13);

        // don't cool and set non-zero to another non-zero
        startGas = gasleft();
        slot1 = 4; // 100 gas
        endGas = gasleft();
        warmGas = startGas - endGas;
        assertEq(slot1, 4);
        assertGt(afterCoolGas, warmGas);
        assertEq(warmGas, 100 + 13);
    }

    function testCool_SSTORE_zero_to_nonzero() public {
        uint256 startGas;
        uint256 endGas;
        uint256 afterCoolGas;
        uint256 warmGas;

        // start as zero
        // set from zero to non-zero
        startGas = gasleft();
        slot0 = 1; // 22.1k gas
        endGas = gasleft();
        afterCoolGas = startGas - endGas;
        assertEq(slot0, 1);
        assertEq(afterCoolGas, 20000 + 2100 + 13);

        slot0 = 0;
        vm.cool(address(this));

        // set from zero to non-zero
        startGas = gasleft();
        slot0 = 1; // 22.1k gas
        endGas = gasleft();
        afterCoolGas = startGas - endGas;
        assertEq(slot0, 1);
        assertEq(afterCoolGas, 20000 + 2100 + 13);

        // don't cool and set non-zero to another non-zero
        startGas = gasleft();
        slot0 = 2; // 100
        endGas = gasleft();
        warmGas = startGas - endGas;
        assertEq(slot0, 2); // persisted state
        assertGt(afterCoolGas, warmGas);
        assertEq(warmGas, 100 + 13);

        // cool again
        // set from non-zero to non-zero
        vm.cool(address(this));
        startGas = gasleft();
        slot0 = 1; // 5k gas
        endGas = gasleft();
        afterCoolGas = startGas - endGas;
        assertEq(slot0, 1);
        assertEq(afterCoolGas, 2900 + 2100 + 13);

        // cool again, set to zero
        // set from zero to non-zero
        slot0 = 0;
        vm.cool(address(this));
        startGas = gasleft();
        slot0 = 1; // 22.1k gas
        endGas = gasleft();
        afterCoolGas = startGas - endGas;
        assertEq(slot0, 1);
        assertEq(afterCoolGas, 20000 + 2100 + 13);

        // cool again
        // set to same value
        vm.cool(address(this));
        startGas = gasleft();
        slot0 = 1; // 2.2k gas
        endGas = gasleft();
        afterCoolGas = startGas - endGas;
        assertEq(slot0, 1);
        assertEq(afterCoolGas, 100 + 2100 + 13);
    }

    function testCool_SSTORE() public {
        uint256 startGas;
        uint256 endGas;
        uint256 afterCoolGas;

        // start as zero
        slot0 = 0;
        assertEq(slot0, 0);

        vm.cool(address(this));

        // set from zero to non-zero
        startGas = gasleft();
        slot0 = 3; // 22.1k gas
        endGas = gasleft();
        afterCoolGas = startGas - endGas;
        assertEq(slot0, 3);
        assertEq(afterCoolGas, 20000 + 2100 + 13);

        vm.cool(address(this));

        // set from non-zero to non-zero
        startGas = gasleft();
        slot0 = 2; // 5k gas
        endGas = gasleft();
        afterCoolGas = startGas - endGas;
        assertEq(slot0, 2);
        assertEq(afterCoolGas, 2900 + 2100 + 13);
    }

    function testCool_call() public {
        uint256 startGas;
        uint256 endGas;
        uint256 afterCoolGas;
        uint256 EXTRA_GAS = 635;

        TestContract test = new TestContract();

        // zero to 1 (20k) but slot is warm
        startGas = gasleft();
        test.setSlot0(1);
        endGas = gasleft();
        afterCoolGas = startGas - endGas;
        assertEq(test.slot0(), 1);
        assertEq(afterCoolGas, 20000 + EXTRA_GAS + 13);

        test.setSlot0(0);
        vm.cool(address(test));

        // zero to 1 (20k) and slot is cold
        startGas = gasleft();
        test.setSlot0(2);
        endGas = gasleft();
        afterCoolGas = startGas - endGas;
        assertEq(test.slot0(), 2);
        assertEq(afterCoolGas, 20000 + 2100 + EXTRA_GAS + 13);

        test.setSlot0(1);
        vm.cool(address(test));

        // 1 to 2 (2900) and slot is cold
        startGas = gasleft();
        test.setSlot0(2);
        endGas = gasleft();
        afterCoolGas = startGas - endGas;
        assertEq(test.slot0(), 2);
        assertEq(afterCoolGas, 2900 + 2100 + EXTRA_GAS + 13);

        test.setSlot0(1);
        vm.cool(address(test));

        // 1 to 1 (100 gas) and slot is cold
        startGas = gasleft();
        test.setSlot0(1);
        endGas = gasleft();
        afterCoolGas = startGas - endGas;
        assertEq(test.slot0(), 1);
        assertEq(afterCoolGas, 100 + 2100 + EXTRA_GAS + 13);

        test.setBoth(0);
        vm.cool(address(test));

        // both 0 to 1 (20k * 2)
        startGas = gasleft();
        test.setBoth(1);
        endGas = gasleft();
        afterCoolGas = startGas - endGas;
        assertEq(test.slot0(), 1);
        assertEq(test.slot1(), 1);
        assertEq(afterCoolGas, 20000 * 2 + 2100 * 2 + EXTRA_GAS);

        test.setSlot0(0);
        vm.cool(address(test));

        // slot0 from 0 to 2 (20k)
        // slot1 from 1 to 2 (2900)
        startGas = gasleft();
        test.setBoth(2);
        endGas = gasleft();
        afterCoolGas = startGas - endGas;
        assertEq(test.slot0(), 2);
        assertEq(test.slot1(), 2);
        assertEq(afterCoolGas, 20000 + 2900 + 2100 * 2 + EXTRA_GAS);
    }
}

contract TestContract {
    uint256 public slot0 = 0;
    uint256 public slot1 = 1;

    function setSlot0(uint256 num) public {
        slot0 = num;
    }

    function setSlot1(uint256 num) public {
        slot1 = num;
    }

    function setBoth(uint256 num) public {
        slot0 = num;
        slot1 = num;
    }
}
