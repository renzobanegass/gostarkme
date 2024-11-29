// ***************************************************************************************
//                              FUND TEST
// ***************************************************************************************
use starknet::{ContractAddress, contract_address_const};
use starknet::syscalls::call_contract_syscall;

use snforge_std::{
    declare, ContractClassTrait, start_cheat_caller_address_global, start_cheat_caller_address,
    cheat_caller_address, CheatSpan, spy_events, EventSpyAssertionsTrait
};

use openzeppelin::utils::serde::SerializedAppend;
use openzeppelin::token::erc20::interface::{IERC20Dispatcher, IERC20DispatcherTrait};


use gostarkme::fund::Fund;
use gostarkme::fund::IFundDispatcher;
use gostarkme::fund::IFundDispatcherTrait;
use gostarkme::constants::{funds::{fund_manager_constants::FundManagerConstants},};
use gostarkme::constants::{funds::{state_constants::FundStates},};
use gostarkme::constants::{funds::{starknet_constants::StarknetConstants},};


fn ID() -> u128 {
    1
}
fn OWNER() -> ContractAddress {
    contract_address_const::<'OWNER'>()
}
fn OTHER_USER() -> ContractAddress {
    contract_address_const::<'USER'>()
}
fn FUND_MANAGER() -> ContractAddress {
    contract_address_const::<FundManagerConstants::FUND_MANAGER_ADDRESS>()
}
fn NAME() -> ByteArray {
    "Lorem impsum, Lorem impsum, Lorem impsum, Lorem impsum, Lorem impsum, Lorem impsum, Lorem impsum, Lorem impsum"
}
fn REASON_1() -> ByteArray {
    "Lorem impsum, Lorem impsum, Lorem impsum, Lorem impsum, Lorem impsum, Lorem impsum, Lorem impsum, Lorem impsum"
}
fn REASON_2() -> ByteArray {
    "Lorem impsum, Lorem impsum, Lorem impsum, Lorem impsum, Lorem impsum, Lorem impsum, Lorem impsum, Lorem impsum"
}
fn GOAL() -> u256 {
    1000
}
fn EVIDENCE_LINK_1() -> ByteArray {
    "Lorem impsum, Lorem impsum, Lorem impsum, Lorem impsum, Lorem impsum, Lorem impsum, Lorem impsum, Lorem impsum"
}
fn EVIDENCE_LINK_2() -> ByteArray {
    "Lorem impsum, Lorem impsum, Lorem impsum, Lorem impsum, Lorem impsum, Lorem impsum, Lorem impsum, Lorem impsum"
}
fn CONTACT_HANDLE_1() -> ByteArray {
    "Lorem impsum, Lorem impsum, Lorem impsum, Lorem impsum, Lorem impsum, Lorem impsum, Lorem impsum, Lorem impsum"
}
fn CONTACT_HANDLE_2() -> ByteArray {
    "Lorem impsum, Lorem impsum, Lorem impsum, Lorem impsum, Lorem impsum, Lorem impsum, Lorem impsum, Lorem impsum"
}
fn VALID_ADDRESS_1() -> ContractAddress {
    contract_address_const::<FundManagerConstants::VALID_ADDRESS_1>()
}
fn VALID_ADDRESS_2() -> ContractAddress {
    contract_address_const::<FundManagerConstants::VALID_ADDRESS_2>()
}
fn _setup_() -> ContractAddress {
    let contract = declare("Fund").unwrap();
    let mut calldata: Array<felt252> = array![];
    calldata.append_serde(ID());
    calldata.append_serde(OWNER());
    calldata.append_serde(NAME());
    calldata.append_serde(GOAL());
    calldata.append_serde(EVIDENCE_LINK_1());
    calldata.append_serde(CONTACT_HANDLE_1());
    calldata.append_serde(REASON_1());
    let (contract_address, _) = contract.deploy(@calldata).unwrap();
    contract_address
}
// ***************************************************************************************
//                              TEST
// ***************************************************************************************
#[test]
#[fork("Mainnet")]
fn test_constructor() {
    let contract_address = _setup_();
    let dispatcher = IFundDispatcher { contract_address };
    let id = dispatcher.getId();
    let owner = dispatcher.getOwner();
    let name = dispatcher.getName();
    let reason = dispatcher.getReason();
    let up_votes = dispatcher.getUpVotes();
    let goal = dispatcher.getGoal();
    let current_goal_state = dispatcher.get_current_goal_state();
    let state = dispatcher.getState();
    assert(id == ID(), 'Invalid id');
    assert(owner == OWNER(), 'Invalid owner');
    assert(name == NAME(), 'Invalid name');
    assert(reason == REASON_1(), 'Invalid reason');
    assert(up_votes == 0, 'Invalid up votes');
    assert(goal == GOAL(), 'Invalid goal');
    assert(current_goal_state == 0, 'Invalid current goal state');
    assert(state == 1, 'Invalid state');
}

#[test]
fn test_set_name() {
    let contract_address = _setup_();
    let dispatcher = IFundDispatcher { contract_address };
    let name = dispatcher.getName();
    assert(name == NAME(), 'Invalid name');
    start_cheat_caller_address_global(OWNER());
    dispatcher.setName("NEW_NAME");
    let new_name = dispatcher.getName();
    assert(new_name == "NEW_NAME", 'Set name method not working')
}

#[test]
fn test_set_reason() {
    let contract_address = _setup_();
    let dispatcher = IFundDispatcher { contract_address };
    let reason = dispatcher.getReason();
    assert(reason == REASON_1(), 'Invalid reason');
    start_cheat_caller_address_global(OWNER());
    dispatcher.setReason(REASON_2());
    let new_reason = dispatcher.getReason();
    assert(new_reason == REASON_2(), 'Set reason method not working')
}

#[test]
fn test_set_goal_by_admins() {
    let contract_address = _setup_();
    let dispatcher = IFundDispatcher { contract_address };

    let initial_goal = dispatcher.getGoal();
    assert(initial_goal == GOAL(), 'Initial goal is incorrect');

    start_cheat_caller_address_global(VALID_ADDRESS_1());
    dispatcher.setGoal(123);
    let updated_goal_1 = dispatcher.getGoal();
    assert(updated_goal_1 == 123, 'Failed to update goal');

    start_cheat_caller_address_global(VALID_ADDRESS_2());
    dispatcher.setGoal(456);
    let updated_goal_2 = dispatcher.getGoal();
    assert(updated_goal_2 == 456, 'Failed to update goal');
}

#[test]
#[should_panic(expected: ("You are not the fund manager",))]
fn test_set_goal_unauthorized() {
    let contract_address = _setup_();
    let dispatcher = IFundDispatcher { contract_address };
    // Change the goal without being the fund manager
    dispatcher.setGoal(22);
}

#[test]
fn test_receive_vote_successful() {
    let contract_address = _setup_();
    let dispatcher = IFundDispatcher { contract_address };
    dispatcher.receiveVote();
    let me = dispatcher.getVoter();
    // Owner vote, fund have one vote
    assert(me == 1, 'Owner is not in the voters');
    let votes = dispatcher.getUpVotes();
    assert(votes == 1, 'Vote unuseccessful');
}

#[test]
#[should_panic(expected: ('User already voted!',))]
fn test_receive_vote_unsuccessful_double_vote() {
    let contract_address = _setup_();
    let dispatcher = IFundDispatcher { contract_address };
    dispatcher.receiveVote();
    let me = dispatcher.getVoter();
    // Owner vote, fund have one vote
    assert(me == 1, 'Owner is not in the voters');
    let votes = dispatcher.getUpVotes();
    assert(votes == 1, 'Vote unuseccessful');
    // Owner vote, second time
    dispatcher.receiveVote();
}

// #[test]
// #[fork("Mainnet")]
// fn test_receive_donation_successful() {
//     let contract_address = _setup_();
//     let dispatcher = IFundDispatcher { contract_address };
//     let goal: u256 = 10;
//     let minter_address = contract_address_const::<StarknetConstants::STRK_TOKEN_MINTER_ADDRESS>();
//     let token_address = contract_address_const::<StarknetConstants::STRK_TOKEN_ADDRESS>();
//     let token_dispatcher = IERC20Dispatcher { contract_address: token_address };
//     // Put state as recollecting dons
//     dispatcher.setState(2);
//     // Put 10 strks as goal, only fund manager
//     start_cheat_caller_address(contract_address, FUND_MANAGER());
//     dispatcher.setGoal(goal);
//     // fund the manager with STRK token
//     cheat_caller_address(token_address, minter_address, CheatSpan::TargetCalls(1));
//     let mut calldata = array![];
//     calldata.append_serde(FUND_MANAGER());
//     calldata.append_serde(goal);
//     call_contract_syscall(token_address, selector!("permissioned_mint"), calldata.span()).unwrap();
//     // approve
//     cheat_caller_address(token_address, FUND_MANAGER(), CheatSpan::TargetCalls(1));
//     token_dispatcher.approve(contract_address, goal);
//     // Donate 5 strks
//     dispatcher.update_receive_donation(goal / 2);
//     let current_goal_state = dispatcher.get_current_goal_state();
//     assert(current_goal_state == goal / 2, 'Receive donation not working');
//     // Donate 5 strks, the goal is done
//     dispatcher.update_receive_donation(goal / 2);
//     let state = dispatcher.getState();
//     assert(state == 3, 'State should be close');
// }

#[test]
fn test_new_vote_received_event_emitted_successful() {
    let contract_address = _setup_();
    let dispatcher = IFundDispatcher { contract_address };

    let mut spy = spy_events();

    start_cheat_caller_address(contract_address, OTHER_USER());
    dispatcher.receiveVote();

    spy
        .assert_emitted(
            @array![
                (
                    contract_address,
                    Fund::Event::NewVoteReceived(
                        Fund::NewVoteReceived {
                            voter: OTHER_USER(), fund: contract_address, votes: 1
                        }
                    )
                )
            ]
        );
}

// #[test]
// #[fork("Mainnet")]
// fn test_emit_event_donation_withdraw() {
//     //Set up contract addresses
//     let contract_address = _setup_();
//     let goal: u256 = 10;

//     let dispatcher = IFundDispatcher { contract_address };
//     let minter_address = contract_address_const::<StarknetConstants::STRK_TOKEN_MINTER_ADDRESS>();
//     let token_address = contract_address_const::<StarknetConstants::STRK_TOKEN_ADDRESS>();
//     let token_dispatcher = IERC20Dispatcher { contract_address: token_address };

//     //Set up donation call
//     dispatcher.setState(2);
//     // Put 10 strks as goal, only fund manager
//     start_cheat_caller_address(contract_address, FUND_MANAGER());
//     dispatcher.setGoal(goal);
//     // fund the manager with STRK token
//     cheat_caller_address(token_address, minter_address, CheatSpan::TargetCalls(1));
//     let mut calldata = array![];
//     calldata.append_serde(FUND_MANAGER());
//     calldata.append_serde(goal);
//     call_contract_syscall(token_address, selector!("permissioned_mint"), calldata.span()).unwrap();
//     // approve
//     cheat_caller_address(token_address, FUND_MANAGER(), CheatSpan::TargetCalls(1));
//     token_dispatcher.approve(contract_address, goal);

//     dispatcher.update_receive_donation(goal);

//     start_cheat_caller_address_global(OWNER());
//     cheat_caller_address(token_address, OWNER(), CheatSpan::TargetCalls(1));

//     // Spy on emitted events and call the withdraw function
//     let mut spy = spy_events();
//     dispatcher.withdraw();

//     // Verify the expected event was emitted with the correct values
//     spy
//         .assert_emitted(
//             @array![
//                 (
//                     contract_address,
//                     Fund::Event::DonationWithdraw(
//                         Fund::DonationWithdraw {
//                             owner_address: OWNER(),
//                             fund_contract_address: contract_address,
//                             withdrawn_amount: 10
//                         }
//                     )
//                 )
//             ]
//         );
// }

#[test]
#[should_panic(expected: ("You are not the owner",))]
fn test_withdraw_with_wrong_owner() {
    let contract_address = _setup_();

    // call withdraw fn with wrong owner 
    start_cheat_caller_address_global(OTHER_USER());
    IFundDispatcher { contract_address }.withdraw();
}

#[test]
#[should_panic(expected: ('Fund not close goal yet.',))]
fn test_withdraw_with_non_closed_state() {
    let contract_address = _setup_();
    let fund_dispatcher = IFundDispatcher { contract_address };

    start_cheat_caller_address_global(FUND_MANAGER());
    // set goal
    fund_dispatcher.setGoal(500_u256);

    start_cheat_caller_address_global(OWNER());
    // withdraw funds
    fund_dispatcher.withdraw();
}

// #[test]
// #[fork("Mainnet")]
// fn test_withdraw() {
//     let contract_address = _setup_();
//     let goal: u256 = 500;

//     let dispatcher = IFundDispatcher { contract_address };
//     let minter_address = contract_address_const::<StarknetConstants::STRK_TOKEN_MINTER_ADDRESS>();
//     let token_address = contract_address_const::<StarknetConstants::STRK_TOKEN_ADDRESS>();
//     let token_dispatcher = IERC20Dispatcher { contract_address: token_address };

//     //Set donation state
//     dispatcher.setState(2);

//     start_cheat_caller_address(contract_address, FUND_MANAGER());
//     dispatcher.setGoal(goal);

//     cheat_caller_address(token_address, minter_address, CheatSpan::TargetCalls(1));
//     let mut calldata = array![];
//     calldata.append_serde(FUND_MANAGER());
//     calldata.append_serde(goal);
//     call_contract_syscall(token_address, selector!("permissioned_mint"), calldata.span()).unwrap();

//     cheat_caller_address(token_address, FUND_MANAGER(), CheatSpan::TargetCalls(1));
//     token_dispatcher.approve(contract_address, goal);

//     dispatcher.update_receive_donation(goal);

//     start_cheat_caller_address_global(OWNER());
//     cheat_caller_address(token_address, OWNER(), CheatSpan::TargetCalls(1));

//     let owner_balance_before = token_dispatcher.balance_of(OWNER());
//     let fund_balance_before = token_dispatcher.balance_of(contract_address);

//     // withdraw
//     dispatcher.withdraw();

//     let owner_balance_after = token_dispatcher.balance_of(OWNER());
//     let fund_balance_after = token_dispatcher.balance_of(contract_address);

//     assert(owner_balance_after == (owner_balance_before + goal), 'wrong owner balance');
//     assert((fund_balance_before - goal) == fund_balance_after, 'wrong fund balance');
// }

#[test]
#[fork("Mainnet")]
fn test_emit_event_donation_received() {
    //Initial configuration of contract addresses and donation targets
    let contract_address = _setup_();
    let goal: u256 = 10;
    let dispatcher = IFundDispatcher { contract_address };
    let minter_address = contract_address_const::<StarknetConstants::STRK_TOKEN_MINTER_ADDRESS>();
    let token_address = contract_address_const::<StarknetConstants::STRK_TOKEN_ADDRESS>();
    let token_dispatcher = IERC20Dispatcher { contract_address: token_address };

    //Donation target configuration in the dispatcher
    start_cheat_caller_address(contract_address, VALID_ADDRESS_1());
    dispatcher.setState(2);
    start_cheat_caller_address(contract_address, FUND_MANAGER());
    dispatcher.setGoal(goal);

    //Provision of STRK token to the fund manager
    cheat_caller_address(token_address, minter_address, CheatSpan::TargetCalls(1));
    let mut calldata = array![];
    calldata.append_serde(FUND_MANAGER());
    calldata.append_serde(goal);
    call_contract_syscall(token_address, selector!("permissioned_mint"), calldata.span()).unwrap();

    //Approve
    cheat_caller_address(token_address, FUND_MANAGER(), CheatSpan::TargetCalls(1));
    token_dispatcher.approve(contract_address, goal);
    let mut spy = spy_events();

    //Receipt of the donation at the dispatcher
    dispatcher.update_receive_donation(goal);
    start_cheat_caller_address_global(FUND_MANAGER());

    //Verification of the current balance and issuance of the expected event
    let current_balance = dispatcher.get_current_goal_state();
    spy
        .assert_emitted(
            @array![
                (
                    contract_address,
                    Fund::Event::DonationReceived(
                        Fund::DonationReceived {
                            current_balance,
                            donated_strks: goal,
                            donator_address: FUND_MANAGER(),
                            fund_contract_address: contract_address,
                        }
                    )
                )
            ]
        );
}

#[test]
fn test_set_evidence_link() {
    let contract_address = _setup_();
    let dispatcher = IFundDispatcher { contract_address };
    let evidence_link = dispatcher.get_evidence_link();
    assert(evidence_link == EVIDENCE_LINK_1(), 'Invalid evidence_link');
    start_cheat_caller_address_global(OWNER());
    dispatcher.set_evidence_link(EVIDENCE_LINK_2());
    let new_evidence_link = dispatcher.get_evidence_link();
    assert(new_evidence_link == EVIDENCE_LINK_2(), 'Set evidence method not working')
}

#[test]
#[should_panic(expected: ("You are not the owner",))]
fn test_set_evidence_link_wrong_owner() {
    let contract_address = _setup_();

    // call set_evidence_link fn with wrong owner 
    start_cheat_caller_address_global(OTHER_USER());
    IFundDispatcher { contract_address }.set_evidence_link(EVIDENCE_LINK_2());
}

#[test]
fn test_set_contact_handle() {
    let contract_address = _setup_();
    let dispatcher = IFundDispatcher { contract_address };
    let contact_handle = dispatcher.get_contact_handle();
    assert(contact_handle == CONTACT_HANDLE_1(), 'Invalid contact handle');
    start_cheat_caller_address_global(OWNER());
    dispatcher.set_contact_handle(CONTACT_HANDLE_2());
    let new_contact_handle = dispatcher.get_contact_handle();
    assert(new_contact_handle == CONTACT_HANDLE_2(), 'Set contact method not working')
}

#[test]
#[should_panic(expected: ("You are not the owner",))]
fn test_set_contact_handle_wrong_owner() {
    let contract_address = _setup_();

    // call set_contact_handle fn with wrong owner 
    start_cheat_caller_address_global(OTHER_USER());
    IFundDispatcher { contract_address }.set_contact_handle(CONTACT_HANDLE_2());
}
