// SPDX-License-Identifier: MIT

module bifrost::remote_calls_meta {
    use wormhole::external_address::{Self, ExternalAddress};

    public struct RemoteCallMeta has drop {
        to: ExternalAddress,
        calldata: vector<u8>,
    }

    public struct RemoteCallsMeta has drop {
        remote_calls: vector<RemoteCallMeta>,
    }

    public fun new(
        to: vector<ExternalAddress>,
        calldata: vector<vector<u8>>,
    ): RemoteCallsMeta {
        let mut remote_calls = vector::empty<RemoteCallMeta>();
        let mut i = 0;
        let n = vector::length(&to);
        while (i < n) {
            let call = RemoteCallMeta {
                to: *vector::borrow(&to, i),
                calldata: *vector::borrow(&calldata, i),
            };
            vector::push_back(&mut remote_calls, call);
            i = i + 1;
        };
        RemoteCallsMeta { remote_calls }
    }

    public(package) fun serialize(meta: RemoteCallsMeta): vector<u8>  {
        let mut buf = vector::empty<u8>();
        let mut i = 0;
        let n = vector::length(&meta.remote_calls);
        while (i < n) {
            let call = vector::borrow(&meta.remote_calls, i);
            vector::append(&mut buf, external_address::to_bytes(call.to));
            vector::append(&mut buf, call.calldata);
            i = i + 1;
        };
        buf
    }   
}