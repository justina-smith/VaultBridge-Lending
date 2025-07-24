;; Title: VaultBridge Lending Protocol
;;
;; Summary:
;; Revolutionary cross-chain lending infrastructure that transforms idle Bitcoin 
;; into productive capital while preserving asset custody and long-term growth potential.
;;
;; Description:
;; VaultBridge revolutionizes DeFi lending by creating a seamless bridge between 
;; Bitcoin's store-of-value properties and Stacks' smart contract capabilities.
;; Users can unlock liquidity from their Bitcoin holdings without selling, 
;; maintaining full exposure to BTC appreciation while accessing STX liquidity.

;; CONSTANTS - Error Codes & System Parameters

;; Authorization and Access Control
(define-constant CONTRACT-OWNER tx-sender)
(define-constant ERR-NOT-AUTHORIZED (err u100))

;; Lending Operation Errors
(define-constant ERR-INSUFFICIENT-COLLATERAL (err u101))
(define-constant ERR-BELOW-MINIMUM (err u102))
(define-constant ERR-INVALID-AMOUNT (err u103))
(define-constant ERR-LOAN-NOT-FOUND (err u107))
(define-constant ERR-LOAN-NOT-ACTIVE (err u108))

;; System State Errors
(define-constant ERR-ALREADY-INITIALIZED (err u104))
(define-constant ERR-NOT-INITIALIZED (err u105))
(define-constant ERR-INVALID-LIQUIDATION (err u106))

;; Validation Errors
(define-constant ERR-INVALID-LOAN-ID (err u109))
(define-constant ERR-INVALID-PRICE (err u110))
(define-constant ERR-INVALID-ASSET (err u111))

;; Supported Collateral Assets
(define-constant VALID-ASSETS (list "BTC" "STX"))

;; DATA VARIABLES - Protocol State Management

;; Protocol Initialization State
(define-data-var platform-initialized bool false)

;; Risk Management Parameters
(define-data-var minimum-collateral-ratio uint u150) ;; 150% minimum collateral ratio
(define-data-var liquidation-threshold uint u120)    ;; 120% liquidation trigger point
(define-data-var platform-fee-rate uint u1)          ;; 1% platform fee on loans

;; Platform Metrics & Analytics
(define-data-var total-btc-locked uint u0)           ;; Total BTC collateral in protocol
(define-data-var total-loans-issued uint u0)         ;; Cumulative loan counter

;; DATA MAPS - Core Protocol Storage

;; Primary Loan Storage Structure
(define-map loans
    { loan-id: uint }
    {
        borrower: principal,
        collateral-amount: uint,
        loan-amount: uint,
        interest-rate: uint,
        start-height: uint,
        last-interest-calc: uint,
        status: (string-ascii 20)
    }
)

;; User Loan Relationship Tracking
(define-map user-loans
    { user: principal }
    { active-loans: (list 10 uint) }
)

;; Oracle Price Feed Integration
(define-map collateral-prices
    { asset: (string-ascii 3) }
    { price: uint }
)

;; PRIVATE FUNCTIONS - Internal Protocol Logic

;; Calculate Current Collateral-to-Loan Ratio (Percentage)
(define-private (calculate-collateral-ratio (collateral uint) (loan uint) (btc-price uint))
    (let
        (
            (collateral-value (* collateral btc-price))
            (ratio (* (/ collateral-value loan) u100))
        )
        ratio
    )
)

;; Calculate Interest Accrued Over Time Period
(define-private (calculate-interest (principal uint) (rate uint) (blocks uint))
    (let
        (
            (interest-per-block (/ (* principal rate) (* u100 u144))) ;; Daily rate / blocks per day
            (total-interest (* interest-per-block blocks))
        )
        total-interest
    )
)

;; Automated Liquidation Check & Execution
(define-private (check-liquidation (loan-id uint))
    (let
        (
            (loan (unwrap! (map-get? loans {loan-id: loan-id}) ERR-LOAN-NOT-FOUND))
            (btc-price (unwrap! (get price (map-get? collateral-prices {asset: "BTC"})) ERR-NOT-INITIALIZED))
            (current-ratio (calculate-collateral-ratio (get collateral-amount loan) (get loan-amount loan) btc-price))
        )
        (if (<= current-ratio (var-get liquidation-threshold))
            (liquidate-position loan-id)
            (ok true)
        )
    )
)

;; Execute Liquidation of Undercollateralized Position
(define-private (liquidate-position (loan-id uint))
    (let
        (
            (loan (unwrap! (map-get? loans {loan-id: loan-id}) ERR-LOAN-NOT-FOUND))
            (borrower (get borrower loan))
        )
        (begin
            (map-set loans
                {loan-id: loan-id}
                (merge loan {status: "liquidated"})
            )
            (map-delete user-loans {user: borrower})
            (ok true)
        )
    )
)

;; Validate Loan ID Within Acceptable Range
(define-private (validate-loan-id (loan-id uint))
    (and 
        (> loan-id u0)
        (<= loan-id (var-get total-loans-issued))
    )
)

;; Validate Asset Against Supported List
(define-private (is-valid-asset (asset (string-ascii 3)))
    (is-some (index-of VALID-ASSETS asset))
)

;; Validate Price Data Integrity
(define-private (is-valid-price (price uint))
    (and 
        (> price u0)
        (<= price u1000000000000) ;; Maximum reasonable price ceiling
    )
)

;; Helper Function for Loan List Filtering
(define-private (not-equal-loan-id (id uint))
    (not (is-eq id id))
)

;; PUBLIC FUNCTIONS - Platform Administration

;; Initialize Protocol - Required Before Operations
(define-public (initialize-platform)
    (begin
        (asserts! (is-eq tx-sender CONTRACT-OWNER) ERR-NOT-AUTHORIZED)
        (asserts! (not (var-get platform-initialized)) ERR-ALREADY-INITIALIZED)
        (var-set platform-initialized true)
        (ok true)
    )
)

;; Update Minimum Collateral Ratio Requirement
(define-public (update-collateral-ratio (new-ratio uint))
    (begin
        (asserts! (is-eq tx-sender CONTRACT-OWNER) ERR-NOT-AUTHORIZED)
        (asserts! (>= new-ratio u110) ERR-INVALID-AMOUNT)
        (var-set minimum-collateral-ratio new-ratio)
        (ok true)
    )
)

;; Update Liquidation Threshold Parameters
(define-public (update-liquidation-threshold (new-threshold uint))
    (begin
        (asserts! (is-eq tx-sender CONTRACT-OWNER) ERR-NOT-AUTHORIZED)
        (asserts! (>= new-threshold u100) ERR-INVALID-AMOUNT)
        (var-set liquidation-threshold new-threshold)
        (ok true)
    )
)

;; Update Oracle Price Feed Data
(define-public (update-price-feed (asset (string-ascii 3)) (new-price uint))
    (begin
        (asserts! (is-eq tx-sender CONTRACT-OWNER) ERR-NOT-AUTHORIZED)
        ;; Comprehensive Asset & Price Validation
        (asserts! (is-valid-asset asset) ERR-INVALID-ASSET)
        (asserts! (is-valid-price new-price) ERR-INVALID-PRICE)
        
        ;; Execute Price Update After Validation
        (ok (map-set collateral-prices
            {asset: asset}
            {price: new-price}
        ))
    )
)

;; PUBLIC FUNCTIONS - Core Lending Operations

;; Deposit Collateral Into Protocol Vault
(define-public (deposit-collateral (amount uint))
    (begin
        (asserts! (var-get platform-initialized) ERR-NOT-INITIALIZED)
        (asserts! (> amount u0) ERR-INVALID-AMOUNT)
        (var-set total-btc-locked (+ (var-get total-btc-locked) amount))
        (ok true)
    )
)

;; Request Loan Against Deposited Collateral
(define-public (request-loan (collateral uint) (loan-amount uint))
    (let
        (
            (btc-price (unwrap! (get price (map-get? collateral-prices {asset: "BTC"})) ERR-NOT-INITIALIZED))
            (collateral-value (* collateral btc-price))
            (required-collateral (* loan-amount (var-get minimum-collateral-ratio)))
            (loan-id (+ (var-get total-loans-issued) u1))
        )
        (begin
            (asserts! (var-get platform-initialized) ERR-NOT-INITIALIZED)
            (asserts! (>= collateral-value required-collateral) ERR-INSUFFICIENT-COLLATERAL)
            
            ;; Create New Loan Record
            (map-set loans
                {loan-id: loan-id}
                {
                    borrower: tx-sender,
                    collateral-amount: collateral,
                    loan-amount: loan-amount,
                    interest-rate: u5, ;; 5% annual interest rate
                    start-height: stacks-block-height,
                    last-interest-calc: stacks-block-height,
                    status: "active"
                }
            )
            
            ;; Update User Loan Tracking
            (match (map-get? user-loans {user: tx-sender})
                existing-loans (map-set user-loans
                    {user: tx-sender}
                    {active-loans: (unwrap! (as-max-len? (append (get active-loans existing-loans) loan-id) u10) ERR-INVALID-AMOUNT)}
                )
                (map-set user-loans
                    {user: tx-sender}
                    {active-loans: (list loan-id)}
                )
            )
            
            ;; Update Global Loan Counter
            (var-set total-loans-issued (+ (var-get total-loans-issued) u1))
            (ok loan-id)
        )
    )
)

;; Repay Loan with Accrued Interest
(define-public (repay-loan (loan-id uint) (amount uint))
    (begin
        ;; Primary Loan ID Validation
        (asserts! (validate-loan-id loan-id) ERR-INVALID-LOAN-ID)
        
        (let
            (
                (loan (unwrap! (map-get? loans {loan-id: loan-id}) ERR-LOAN-NOT-FOUND))
                (interest-owed (calculate-interest 
                    (get loan-amount loan)
                    (get interest-rate loan)
                    (- stacks-block-height (get last-interest-calc loan))
                ))
                (total-owed (+ (get loan-amount loan) interest-owed))
            )
            (begin
                ;; Loan Status & Authorization Validation
                (asserts! (is-eq (get status loan) "active") ERR-LOAN-NOT-ACTIVE)
                (asserts! (is-eq (get borrower loan) tx-sender) ERR-NOT-AUTHORIZED)
                (asserts! (>= amount total-owed) ERR-INVALID-AMOUNT)
                
                ;; Update Loan Status to Repaid
                (map-set loans
                    {loan-id: loan-id}
                    (merge loan {
                        status: "repaid",
                        last-interest-calc: stacks-block-height
                    })
                )
                
                ;; Release Collateral from Protocol Vault
                (var-set total-btc-locked (- (var-get total-btc-locked) (get collateral-amount loan)))
                
                ;; Remove from Active Loan Tracking
                (match (map-get? user-loans {user: tx-sender})
                    existing-loans (ok (map-set user-loans
                        {user: tx-sender}
                        {active-loans: (filter not-equal-loan-id (get active-loans existing-loans))}
                    ))
                    (ok false)
                )
            )
        )
    )
)

;; READ-ONLY FUNCTIONS - Protocol Data Access

;; Retrieve Specific Loan Details
(define-read-only (get-loan-details (loan-id uint))
    (map-get? loans {loan-id: loan-id})
)

;; Get All Active Loans for User
(define-read-only (get-user-loans (user principal))
    (map-get? user-loans {user: user})
)

;; Get Current Platform Statistics & Metrics
(define-read-only (get-platform-stats)
    {
        total-btc-locked: (var-get total-btc-locked),
        total-loans-issued: (var-get total-loans-issued),
        minimum-collateral-ratio: (var-get minimum-collateral-ratio),
        liquidation-threshold: (var-get liquidation-threshold)
    }
)

;; Get List of Supported Collateral Assets
(define-read-only (get-valid-assets)
    VALID-ASSETS
)