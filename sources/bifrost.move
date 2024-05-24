// SPDX-License-Identifier: MIT

module bifrost::asgard {
    use sui::table::{Self, Table};
    use wormhole::emitter::{Self, EmitterCap};
    use wormhole::external_address::ExternalAddress;
    use wormhole::state::{State as WormholeState};
    use wormhole::publish_message::{MessageTicket};
    use bifrost::remote_calls_meta::{Self, RemoteCallsMeta};

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

    public fun prepare_remote_calls(
        state: &mut State,
        nonce: u32,
        message: RemoteCallsMeta,
        _ctx: &mut TxContext,
    ): MessageTicket {
        let encoded_message = remote_calls_meta::serialize(message);

        wormhole::publish_message::prepare_message(
            &mut state.emitter_cap,
            nonce,
            encoded_message
        )
    }
}

#[test_only]
module bifrost::asgard_test {
    use sui::test_scenario::{Self};
    use sui::coin::{Self};
    use wormhole::publish_message::{Self};
    use wormhole::wormhole_scenario::{
        return_clock,
        return_state,
        set_up_wormhole,
        take_clock,
        take_state,
        two_people,
    };
    use wormhole::external_address::{Self, ExternalAddress};
    use wormhole::bytes32::Self;

    use bifrost::asgard::{
        init_with_params,
        channel,
        spawn_channel,
        prepare_remote_calls,
        State,
    };
    use bifrost::remote_calls_meta::{Self};

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
            assert!(channel(&state, 1) == external_address::new(data));

            test_scenario::return_shared(state);
        };
        test_scenario::end(my_scenario);
    }

    #[test]
    fun test_prepare_remote_calls() {
        let (user, admin) = two_people();
        let mut my_scenario = test_scenario::begin(admin);
        let scenario = &mut my_scenario;

        // Initialize Wormhole.
        let wormhole_message_fee = 0;
        set_up_wormhole(scenario, wormhole_message_fee);

        // Initialize sender module.
        test_scenario::next_tx(scenario, admin);
        {
            let wormhole_state = take_state(scenario);
            init_with_params(&wormhole_state, test_scenario::ctx(scenario));
            return_state(wormhole_state);
        };

        // Send message as an ordinary user.
        test_scenario::next_tx(scenario, user);
        {
            let mut state = test_scenario::take_shared<State>(scenario);
            let mut wormhole_state = take_state(scenario);
            let the_clock = take_clock(scenario);

            let call_meta = remote_calls_meta::new(
                vector::empty<ExternalAddress>(),
                vector::empty<vector<u8>>(),
            );
            let ticket = prepare_remote_calls(
                &mut state,
                1,
                copy call_meta,
                test_scenario::ctx(scenario),
            );

            
            
            let message_sequence = publish_message::publish_message(
                &mut wormhole_state,
                coin::zero(test_scenario::ctx(scenario)),
                prepare_remote_calls(
                    &mut state,
                    1,
                    call_meta,
                    test_scenario::ctx(scenario),
                ),
                &the_clock,
            );
            std::debug::print(&message_sequence);
            assert!(message_sequence == 1, 0);

            let message_sequence = publish_message::publish_message(
                &mut wormhole_state,
                coin::zero(test_scenario::ctx(scenario)),
                prepare_remote_calls(
                    &mut state,
                    1,
                    call_meta,
                    test_scenario::ctx(scenario),
                ),
                &the_clock,
            );
            assert!(message_sequence == 2, 0);
            
            publish_message::destroy(ticket);

            // Clean up.
            test_scenario::return_shared(state);
            return_state(wormhole_state);
            return_clock(the_clock);
        };

        test_scenario::end(my_scenario);
    }
}
