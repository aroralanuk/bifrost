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

    public fun serialze(meta: RemoteCallsMeta): vector<u8>  {
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