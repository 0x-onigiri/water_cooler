module galliun::cooler_factory {
    // === Imports ===

    use std::string::{String};
    use sui::{
        sui::SUI,
        coin::{Self, Coin},
        balance::{Self, Balance},
    };
    use galliun::water_cooler::{Self};
    use galliun::mint::{Self};

    // === Errors ===

    const EInsufficientBalance: u64 = 0;

    // === Structs ===

    // shared object collecting fees from generated water coolers
    public struct CoolerFactory has key {
        id: UID,
        fee: u64,
        balance: Balance<SUI>,
    }

    public struct FactoryOwnerCap has key, store { id: UID }

    // === Public mutative functions ===

    fun init(ctx: &mut TxContext) {
        transfer::transfer(
            FactoryOwnerCap { id: object::new(ctx) }, 
            ctx.sender()
        );
        
        transfer::share_object(
            CoolerFactory {
                id: object::new(ctx),
                fee: 100,
                balance: balance::zero(),
            }
        );
    }

    public entry fun buy_water_cooler(
        self: &mut CoolerFactory, 
        payment: Coin<SUI>,
        name: String, 
        description: String, 
        image_url: String,
        supply: u64, 
        treasury: address, 
        ctx: &mut TxContext
    ) {
        assert!(payment.value() == self.fee, EInsufficientBalance);
        // Create a WaterCooler and give it to the buyer
        water_cooler::create_water_cooler(name, description, image_url, supply, treasury, ctx);
        // Create a Mint distributer and give it to the buyer
        mint::create_mint_distributer(ctx);
        // Put fee into factory balance
        self.balance.join(payment.into_balance());
    }

    
    public entry fun update_fee(_: &FactoryOwnerCap, self: &mut CoolerFactory, fee: u64) {
        self.fee = fee;
    }
    
    public fun claim_fee(_: &FactoryOwnerCap, self: &mut CoolerFactory, ctx: &mut TxContext) : Coin<SUI> {
        let value = self.balance.value();
        let coin = coin::take(&mut self.balance, value, ctx);
        coin
    }

    public fun get_balance(self: &CoolerFactory) : u64 {
        self.balance.value()
    }
    public fun get_fee(self: &CoolerFactory) : u64 {
        self.fee
    }

    // === Test Functions ===

    #[test_only]
    public fun init_for_cooler(ctx: &mut TxContext) {
        init(ctx);
    }

}
