// SPDX-License-Identifier: MIT

module bifrost::asgard {
    use std::string;
    use sui::table::{Self, Table};
    use sui::object::{Self, UID};
    use sui::transfer;
    use sui::tx_context::{Self, TxContext};
    use wormhole::emitter::{Self, EmitterCap};
    use wormhole::external_address::ExternalAddress;
    use wormhole::state::{State as WormholeState};
    use wormhole::publish_message::{MessageTicket};

    public struct State has key, store {
        id: UID,
        emitter_cap: EmitterCap,
        channels: Table<u32, ExternalAddress>,
    }

    /// Register ourselves as a wormhole emitter. This gives back an
    /// `EmitterCap` which will be required to send messages through
    /// wormhole.
    public fun init_with_params(
        wormhole_state: &WormholeState,
        ctx: &mut TxContext
    ) {
        let channels = table::new<u32, ExternalAddress>(ctx);
        transfer::share_object(
            State {
                id: object::new(ctx),
                emitter_cap: emitter::new(wormhole_state, ctx),
                channels,
            }
        );
    }

    public fun spawn_channel(
        state: &mut State,
        channel_id: u32,
        external_address: ExternalAddress,
        _ctx: &mut TxContext,
    ) {
        table::add(&mut state.channels, channel_id, external_address);
    }

    public fun channel(
        state: &State,
        channel_id: u32,
    ): ExternalAddress {
        *table::borrow(&state.channels, channel_id)
    }

    // public fun prepare_remote_calls(
    //     state: &State,
    //     channel_id: u32,
    //     message: string,
    //     _ctx: &mut TxContext,
    // ): MessageTicket {

    // }

    // public fun serial_remote_calls(
    //     state: &State,
    //     channel_id: u32,
    //     message: string,
    //     _ctx: &mut TxContext,
    // ) {
    //     let external_address = channel(state, channel_id);
    //     emitter::send_message(state.emitter_cap, external_address, message);
    // }
    
}

#[test_only]
module bifrost::asgard_test {
    use sui::table::{Self};
    use sui::test_scenario::{Self};
    use wormhole::wormhole_scenario::{
        return_clock,
        return_state,
        set_up_wormhole,
        take_clock,
        take_state,
        two_people,
    };
    use wormhole::external_address::Self;
    use wormhole::bytes32::Self;

    use bifrost::asgard::{
        init_with_params,
        channel,
        spawn_channel,
        State,
    };

    #[test]
    fun test_spawn_channel() {
        let (user, admin) = two_people();
        let mut my_scenario = test_scenario::begin(admin);
        let scenario = &mut my_scenario;

        let wormhole_message_fee = 0;
        set_up_wormhole(scenario, wormhole_message_fee);

        test_scenario::next_tx(scenario, admin);
        {
            let wormhole_state = take_state(scenario);
            init_with_params(&wormhole_state, test_scenario::ctx(scenario));
            return_state(wormhole_state);
        };

        test_scenario::next_tx(scenario, user);
        { 
            let data =
            bytes32::new(
                x"1234567891234567891234567891234512345678912345678912345678912345"
            );
            let mut state = test_scenario::take_shared<State>(scenario);
            spawn_channel(
                &mut state,
                1,
                external_address::new(data),
                test_scenario::ctx(scenario),
            );
            assert!(channel(&mut state, 1) == external_address::new(data));

            test_scenario::return_shared(state);
        };
        test_scenario::end(my_scenario);
    }
}
