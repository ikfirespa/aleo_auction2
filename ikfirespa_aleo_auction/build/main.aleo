program aleo_auction.aleo;

struct Auction:
    item_id as u64;
    creator as address;
    starting_bid as u64;
    highest_bid as u64;
    highest_bidder as address;
    end_time as u32;
    active as boolean;


mapping auctions:
	key as u64.public;
	value as Auction.public;


mapping global_setting:
	key as u8.public;
	value as u64.public;


mapping escrow:
	key as address.public;
	value as u64.public;

function start_auction:
    input r0 as u64.private;
    input r1 as u64.private;
    input r2 as u32.private;
    cast r0 self.caller r1 r1 self.caller r2 true into r3 as Auction;
    async start_auction r3 into r4;
    output r3 as Auction.private;
    output r4 as aleo_auction.aleo/start_auction.future;

finalize start_auction:
    input r0 as Auction.public;
    get.or_use global_setting[0u8] 0u64 into r1;
    set r0 into auctions[r1];
    add r1 1u64 into r2;
    set r2 into global_setting[0u8];


function place_bid:
    input r0 as u64.private;
    input r1 as u64.private;
    async place_bid self.caller r0 r1 into r2;
    output r2 as aleo_auction.aleo/place_bid.future;

finalize place_bid:
    input r0 as address.public;
    input r1 as u64.public;
    input r2 as u64.public;
    get auctions[r1] into r3;
    assert.eq r3.active true;
    gt r2 r3.highest_bid into r4;
    assert.eq r4 true;
    cast r3.item_id r3.creator r3.starting_bid r2 r0 r3.end_time r3.active into r5 as Auction;
    get.or_use escrow[r0] 0u64 into r6;
    set r2 into escrow[r0];
    set r3 into auctions[r1];


function close_auction:
    input r0 as u64.private;
    input r1 as u32.private;
    async close_auction self.caller r0 r1 into r2;
    output r2 as aleo_auction.aleo/close_auction.future;

finalize close_auction:
    input r0 as address.public;
    input r1 as u64.public;
    input r2 as u32.public;
    get auctions[r1] into r3;
    is.eq r0 r3.creator into r4;
    assert.eq r4 true;
    gte r2 r3.end_time into r5;
    assert.eq r5 true;
    get escrow[r3.highest_bidder] into r6;
    cast r3.item_id r3.creator r3.starting_bid r3.highest_bid r3.highest_bidder r3.end_time false into r7 as Auction;
    set r7 into auctions[r1];
    remove escrow[r3.highest_bidder];


function cancel_auction:
    input r0 as u64.private;
    async cancel_auction self.caller r0 into r1;
    output r1 as aleo_auction.aleo/cancel_auction.future;

finalize cancel_auction:
    input r0 as address.public;
    input r1 as u64.public;
    get auctions[r1] into r2;
    is.eq r0 r2.creator into r3;
    assert.eq r3 true;
    get escrow[r2.highest_bidder] into r4;
    cast r2.item_id r2.creator r2.starting_bid r2.highest_bid r2.highest_bidder r2.end_time false into r5 as Auction;
    set r5 into auctions[r1];
    remove escrow[r2.highest_bidder];
