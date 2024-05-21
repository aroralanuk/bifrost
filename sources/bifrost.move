// Copyright (c) 2022, Sui Foundation
// SPDX-License-Identifier: Apache-2.0

module bifrost::asgard {
    use std::string;
    use sui::table::{Self, Table};
    use sui::object::{Self, UID};
    use sui::transfer;
    use sui::tx_context::{Self, TxContext};
    use wormhole::emitter::{Self, EmitterCap};
    use wormhole::external_address::ExternalAddress;
    use wormhole::state::{State as WormholeState};

    public struct State has key, store {
        id: UID,
        emitter_cap: EmitterCap,
    }


    public struct Channel has store {
        channel_id: u32,
        external_address: ExternalAddress,
    }

    public struct ChannelManager has key {
        id: UID,
        channels: Table<u32, Channel>,
    }

    /// Register ourselves as a wormhole emitter. This gives back an
    /// `EmitterCap` which will be required to send messages through
    /// wormhole.
    fun init(
        // wormhole_state: &WormholeState,
        ctx: &mut TxContext
    ) {
        // transfer::share_object(
        //     State {
        //         id: object::new(ctx),
        //         emitter_cap: emitter::new(wormhole_state, ctx)
        //     }
        // );
        let channels = table::new<u32, Channel>(ctx);
        let manager = ChannelManager {
            id: object::new(ctx),
            channels,
        };
        transfer::share_object(manager);
    }

    public fun spawn_channel(
        manager: &mut ChannelManager,
        channel_id: u32,
        external_address: ExternalAddress,
        _ctx: &mut TxContext,
    ) {
        let channel = Channel {
            channel_id,
            external_address,
        };
        table::add(&mut manager.channels, channel_id, channel);
    }


    // spawnChannel
    // callRemote
}
