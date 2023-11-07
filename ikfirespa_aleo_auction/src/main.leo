// The 'aleo_auction' program.
program aleo_auction.aleo {

    // Auction struct to hold auction details
    struct Auction {
        item_id: u64,
        creator: address,
        starting_bid: u64,
        highest_bid: u64,
        highest_bidder: address,
        end_time: u32,
        active: bool
    }

    // Record to track auctions
    mapping auctions: u64 => Auction;
    mapping global_setting: u8 => u64;

    // Record to hold the funds of the highest bidder until the auction ends
    mapping escrow: address => u64;

    // Function to start an auction with the given parameters
    transition start_auction(
        item_id: u64,
        starting_bid: u64,
        end_time: u32
    ) -> Auction {
        let auction: Auction = Auction {
            item_id: item_id,
            creator: self.caller,
            starting_bid: starting_bid,
            highest_bid: starting_bid,
            highest_bidder: self.caller, // Placeholder for an empty address
            end_time: end_time,
            active: true
        };

        return auction then finalize(auction);
    }

    finalize start_auction (auction: Auction) {
        //index start from Zero
        let auction_id: u64 = global_setting.get_or_use(0u8, 0u64);

        auctions.set(auction_id, auction);

        //increament authin id
        global_setting.set(0u8, auction_id+1u64);
    }

    // Function to place a bid on an item
    transition place_bid(
        auction_id: u64,
        bid_amount: u64
    ) {
        return then finalize(self.caller, auction_id, bid_amount);
    }

    finalize place_bid (
        caller: address,
        auction_id: u64,
        bid_amount: u64
    ) {
        // Get the auction from the record using auction_id
        let auction: Auction = auctions.get(auction_id);

        // Ensure the auction is active
        assert(auction.active);

        // Validate bid_amount is greater than the current highest bid
        assert(bid_amount > auction.highest_bid);

        // Update auction's highest_bid and highest_bidder
        let updated_auction: Auction = Auction {
            item_id: auction.item_id,
            creator: auction.creator,
            starting_bid: auction.starting_bid,
            highest_bid: bid_amount,
            highest_bidder: caller, // Placeholder for an empty address
            end_time: auction.end_time,
            active: auction.active
        };


        // Handle transfer of funds to escrow
        let previous_highest_bid: u64 = escrow.get_or_use(caller, 0u64);
        escrow.set(caller, bid_amount);

        // Save the updated auction
        auctions.set(auction_id, auction);
    }

    // Function to close an auction
    transition close_auction(
        auction_id: u64,
        time_now: u32,
    ) {
        return then finalize(self.caller, auction_id, time_now);
    }

    finalize close_auction (
        caller: address,
        auction_id: u64,
        time_now: u32,
    ) {
        // Get the auction from the record using auction_id
        let auction: Auction = auctions.get(auction_id);

        // Ensure only the item owner or a system process can close the auction
        // Here you need to replace `self.is_system_process()` with the actual check for system process
        assert(caller == auction.creator /* || self.is_system_process() */);

        // Check if the auction's end time has been reached
        assert(time_now >= auction.end_time);

        // Transfer the item to the highest bidder
        // Logic for transferring ownership of the item goes here

        // Transfer the funds from escrow to the item owner
        let bid_amount: u64 = escrow.get(auction.highest_bidder);
        // Logic to transfer bid_amount from escrow to the item owner goes here

        // Set auction as inactive
        let updated_auction: Auction = Auction {
            item_id: auction.item_id,
            creator: auction.creator,
            starting_bid: auction.starting_bid,
            highest_bid: auction.highest_bid,
            highest_bidder: auction.highest_bidder,
            end_time: auction.end_time,
            active: false
        };

        // Save the updated auction
        auctions.set(auction_id, updated_auction);

        // Remove the bid from escrow
        escrow.remove(auction.highest_bidder);
    }


    // Function to cancel an auction
    transition cancel_auction(
        auction_id: u64
    ) {
        return then finalize(self.caller, auction_id);
    }

    finalize cancel_auction (
        caller: address,
        auction_id: u64
    ) {
        // Get the auction from the record using auction_id
        let auction: Auction = auctions.get(auction_id);

        // Ensure only the item owner can cancel the auction
        assert(caller == auction.creator);

        // Refund the highest bid from escrow to the highest bidder
        let bid_amount: u64 = escrow.get(auction.highest_bidder);
        // Logic to refund bid_amount to the highest bidder goes here
        // Note that if you need to refund, you should ensure the funds are there

        // Set auction as inactive
        let updated_auction: Auction = Auction {
            item_id: auction.item_id,
            creator: auction.creator,
            starting_bid: auction.starting_bid,
            highest_bid: auction.highest_bid,
            highest_bidder: auction.highest_bidder,
            end_time: auction.end_time,
            active: false
        };

        // Save the updated auction
        auctions.set(auction_id, updated_auction);

        // Remove the bid from escrow if necessary
        escrow.remove(auction.highest_bidder);
    }

}

