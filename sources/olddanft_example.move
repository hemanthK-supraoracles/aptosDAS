module CAFE::olddanft_example {
    use std::signer;
    use std::string::{String, utf8};
    use aptos_framework::object::{Self, Object};
    use aptos_token_objects::aptos_token;
    use aptos_token_objects::collection;
    use aptos_token_objects::token;
    use std::option;
    use std::vector;

    /// Error codes
    const E_NOT_AUTHORIZED: u64 = 1;
    const E_TOKEN_NOT_FOUND: u64 = 2;
    const E_COLLECTION_NOT_FOUND: u64 = 3;

    /// Struct to hold collection configuration
    struct CollectionConfig has key {
        name: String,
        description: String,
        uri: String,
        max_supply: u64
    }

    /// Initialize a new NFT collection
    public entry fun initialize_collection(
        creator: &signer,
        name: String,
        description: String,
        uri: String,
        max_supply: u64,
        royalty_numerator: u64,
        royalty_denominator: u64
    ) {
        let collection_builder =
            collection::create_fixed_collection(
                creator,
                description,
                max_supply,
                name,
                option::none(),
                uri
            );

        // Store collection config
        move_to(
            creator,
            CollectionConfig { name, description, uri, max_supply }
        );
    }

    /// Mint a new NFT
    public entry fun mint_nft(
        creator: &signer,
        collection_name: String,
        token_name: String,
        description: String,
        uri: String
    ) acquires CollectionConfig {
        let creator_addr = signer::address_of(creator);
        assert!(exists<CollectionConfig>(creator_addr), E_COLLECTION_NOT_FOUND);

        let token_builder =
            token::create(
                creator,
                collection_name,
                description,
                token_name,
                option::none(),
                uri
            );

        aptos_token::mint(
            creator,
            collection_name,
            description,
            token_name,
            uri,
            vector::empty(),
            vector::empty(),
            vector::empty()
        );
    }

    /// Transfer an NFT to another address
    public entry fun transfer_nft(
        owner: &signer, token: Object<aptos_token::AptosToken>, to: address
    ) {
        let owner_addr = signer::address_of(owner);
        assert!(object::is_owner(token, owner_addr), E_NOT_AUTHORIZED);

        object::transfer(owner, token, to);
    }

    /// Burn an NFT
    public entry fun burn_nft(
        owner: &signer, token: Object<aptos_token::AptosToken>
    ) {
        let owner_addr = signer::address_of(owner);
        assert!(object::is_owner(token, owner_addr), E_NOT_AUTHORIZED);

        aptos_token::burn(owner, token);
    }

    /// Helper function to get collection object
    public fun get_collection_object(
        creator: address, collection_name: String
    ): Object<collection::Collection> {
        let collection_addr =
            collection::create_collection_address(&creator, &collection_name);
        object::address_to_object<collection::Collection>(collection_addr)
    }

    /// Helper function to get token object
    public fun get_token_object(
        creator: address, collection_name: String, token_name: String
    ): Object<aptos_token::AptosToken> {
        let token_addr =
            token::create_token_address(&creator, &collection_name, &token_name);
        object::address_to_object<aptos_token::AptosToken>(token_addr)
    }

    #[view]
    /// Check if a collection exists
    public fun collection_exists(
        creator: address, collection_name: String
    ): bool {
        let collection_addr =
            collection::create_collection_address(&creator, &collection_name);
        object::object_exists<collection::Collection>(collection_addr)
    }

    #[view]
    /// Check if a token exists
    public fun token_exists(
        creator: address, collection_name: String, token_name: String
    ): bool {
        let token_addr =
            token::create_token_address(&creator, &collection_name, &token_name);
        object::object_exists<aptos_token::AptosToken>(token_addr)
    }
}
