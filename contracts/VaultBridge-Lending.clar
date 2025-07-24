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