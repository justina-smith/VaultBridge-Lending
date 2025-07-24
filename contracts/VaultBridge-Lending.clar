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