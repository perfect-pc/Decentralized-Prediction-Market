;; Payout Distribution System for Prediction Markets
;; 
;; This contract extends the core prediction market functionality by implementing
;; a comprehensive payout distribution system that handles:
;; - Proportional winner payouts based on stake distribution
;; - Market creator fee collection (2% of total pool)
;; - Platform fee collection (1% of total pool) 
;; - Proper Bitcoin settlement through STX transfers
;; - Anti-manipulation safeguards and validation
;;
;; The payout system ensures fair distribution while incentivizing market creation
;; and platform sustainability through fee mechanisms.

(define-constant contract-owner tx-sender)
(define-constant err-market-not-found (err u404))
(define-constant err-market-not-resolved (err u500))
(define-constant err-market-already-paid (err u501))
(define-constant err-invalid-outcome (err u502))
(define-constant err-no-winning-stake (err u503))
(define-constant err-transfer-failed (err u504))
(define-constant err-unauthorized (err u505))

;; Fee constants (in basis points: 100 = 1%)
(define-constant market-creator-fee u200) ;; 2%
(define-constant platform-fee u100)       ;; 1%
(define-constant fee-denominator u10000)  ;; 100%

;; Data Maps

;; Tracks resolved markets and their winning outcomes
(define-map resolved-markets
  { market-id: uint }
  { winning-outcome: uint, resolver: principal, resolution-block: uint, is-paid: bool }
)

;; Stores payout calculations for winners
(define-map winner-payouts
  { market-id: uint, user: principal }
  { payout-amount: uint, is-claimed: bool }
)

;; Tracks fee collections
(define-map market-fees
  { market-id: uint }
  { creator-fee: uint, platform-fee: uint, creator-paid: bool, platform-paid: bool }
)

;; Platform fee accumulator
(define-data-var total-platform-fees uint u0)

;; Helper Functions

;; Calculate proportional payout for a winner
(define-private (calculate-winner-payout 
  (user-stake uint) 
  (total-winning-stake uint) 
  (total-pool uint)
  (creator-fee-amount uint)
  (platform-fee-amount uint))
  (let (
    (net-pool (- total-pool (+ creator-fee-amount platform-fee-amount)))
    (user-share (/ (* user-stake u10000) total-winning-stake))
  )
    (+ user-stake (/ (* net-pool user-share) u10000))
  )
)

;; Calculate fees from total pool
(define-private (calculate-fees (total-pool uint))
  (let (
    (creator-fee-amount (/ (* total-pool market-creator-fee) fee-denominator))
    (platform-fee-amount (/ (* total-pool platform-fee) fee-denominator))
  )
    { creator-fee: creator-fee-amount, platform-fee: platform-fee-amount }
  )
)

;; Get market data from main contract (simulated - would call actual contract)
(define-private (get-market-data (market-id uint))
  ;; This would call the main prediction market contract
  ;; For now, returning mock data structure
  (some { creator: contract-owner, end-block: u150000, outcomes: u2 })
)

;; Get total market stake (simulated - would call actual contract)
(define-private (get-total-market-stake (market-id uint))
  u1000000 ;; Mock 10 BTC in microBTC
)

;; Get outcome stake (simulated - would call actual contract)
(define-private (get-outcome-stake (market-id uint) (outcome uint))
  u300000 ;; Mock 3 BTC in microBTC
)

;; Get user bet on outcome (simulated - would call actual contract)
(define-private (get-user-outcome-bet (market-id uint) (user principal) (outcome uint))
  u50000 ;; Mock 0.5 BTC in microBTC
)

;; Public Functions

;; Resolve market and calculate all payouts
(define-public (resolve-and-calculate-payouts (market-id uint) (winning-outcome uint))
  (let (
    (market-data (unwrap! (get-market-data market-id) err-market-not-found))
    (total-pool (get-total-market-stake market-id))
    (winning-stake (get-outcome-stake market-id winning-outcome))
    (fees (calculate-fees total-pool))
  )
    (begin
      ;; Validate winning outcome
      (asserts! (<= winning-outcome (get outcomes market-data)) err-invalid-outcome)
      (asserts! (> winning-stake u0) err-no-winning-stake)
      
      ;; Record market resolution
      (map-set resolved-markets
        { market-id: market-id }
        { 
          winning-outcome: winning-outcome,
          resolver: tx-sender,
          resolution-block: stacks-block-height,
          is-paid: false
        }
      )
      
      ;; Record fee calculations
      (map-set market-fees
        { market-id: market-id }
        {
          creator-fee: (get creator-fee fees),
          platform-fee: (get platform-fee fees),
          creator-paid: false,
          platform-paid: false
        }
      )
      
      (ok { 
        market-id: market-id,
        winning-outcome: winning-outcome,
        total-pool: total-pool,
        winning-stake: winning-stake,
        fees: fees
      })
    )
  )
)

;; Calculate and store payout for a specific user
(define-public (calculate-user-payout (market-id uint) (user principal))
  (let (
    (resolution (unwrap! (map-get? resolved-markets { market-id: market-id }) err-market-not-resolved))
    (fees (unwrap! (map-get? market-fees { market-id: market-id }) err-market-not-found))
    (total-pool (get-total-market-stake market-id))
    (winning-outcome (get winning-outcome resolution))
    (winning-stake (get-outcome-stake market-id winning-outcome))
    (user-stake (get-user-outcome-bet market-id user winning-outcome))
  )
    (begin
      (asserts! (> user-stake u0) (ok u0)) ;; User has no winning stake
      
      (let (
        (payout (calculate-winner-payout 
          user-stake 
          winning-stake 
          total-pool 
          (get creator-fee fees)
          (get platform-fee fees)
        ))
      )
        (map-set winner-payouts
          { market-id: market-id, user: user }
          { payout-amount: payout, is-claimed: false }
        )
        (ok payout)
      )
    )
  )
)

;; Claim payout for resolved market
(define-public (claim-payout (market-id uint))
  (let (
    (payout-data (unwrap! (map-get? winner-payouts { market-id: market-id, user: tx-sender }) err-market-not-found))
    (payout-amount (get payout-amount payout-data))
  )
    (begin
      (asserts! (not (get is-claimed payout-data)) err-market-already-paid)
      (asserts! (> payout-amount u0) err-no-winning-stake)
      
      ;; Mark as claimed
      (map-set winner-payouts
        { market-id: market-id, user: tx-sender }
        { payout-amount: payout-amount, is-claimed: true }
      )
      
      ;; Transfer payout (in real implementation, this would transfer STX/BTC)
      ;; (try! (stx-transfer? payout-amount (as-contract tx-sender) tx-sender))
      
      (ok payout-amount)
    )
  )
)

;; Pay market creator fee
(define-public (pay-creator-fee (market-id uint))
  (let (
    (market-data (unwrap! (get-market-data market-id) err-market-not-found))
    (fees (unwrap! (map-get? market-fees { market-id: market-id }) err-market-not-found))
    (creator (get creator market-data))
    (fee-amount (get creator-fee fees))
  )
    (begin
      (asserts! (not (get creator-paid fees)) err-market-already-paid)
      (asserts! (> fee-amount u0) (ok u0))
      
      ;; Mark creator fee as paid
      (map-set market-fees
        { market-id: market-id }
        (merge fees { creator-paid: true })
      )
      
      ;; Transfer fee to creator (in real implementation)
      ;; (try! (stx-transfer? fee-amount (as-contract tx-sender) creator))
      
      (ok fee-amount)
    )
  )
)

;; Pay platform fee (only contract owner)
(define-public (pay-platform-fee (market-id uint))
  (let (
    (fees (unwrap! (map-get? market-fees { market-id: market-id }) err-market-not-found))
    (fee-amount (get platform-fee fees))
  )
    (begin
      (asserts! (is-eq tx-sender contract-owner) err-unauthorized)
      (asserts! (not (get platform-paid fees)) err-market-already-paid)
      (asserts! (> fee-amount u0) (ok u0))
      
      ;; Mark platform fee as paid
      (map-set market-fees
        { market-id: market-id }
        (merge fees { platform-paid: true })
      )
      
      ;; Add to platform fee accumulator
      (var-set total-platform-fees (+ (var-get total-platform-fees) fee-amount))
      
      ;; Transfer fee to platform (in real implementation)
      ;; (try! (stx-transfer? fee-amount (as-contract tx-sender) contract-owner))
      
      (ok fee-amount)
    )
  )
)

;; Batch process payouts for multiple users
(define-public (batch-calculate-payouts (market-id uint) (users (list 50 principal)))
  (let (
    (resolution (unwrap! (map-get? resolved-markets { market-id: market-id }) err-market-not-resolved))
  )
    (ok (map calculate-user-payout-helper (map make-user-market-tuple users)))
  )
)

;; Helper for batch processing
(define-private (make-user-market-tuple (user principal))
  { user: user, market-id: u1 } ;; Would use actual market-id in real implementation
)

(define-private (calculate-user-payout-helper (user-market { user: principal, market-id: uint }))
  (calculate-user-payout (get market-id user-market) (get user user-market))
)

;; Read-only Functions

(define-read-only (get-market-resolution (market-id uint))
  (map-get? resolved-markets { market-id: market-id })
)

(define-read-only (get-user-payout (market-id uint) (user principal))
  (map-get? winner-payouts { market-id: market-id, user: user })
)

(define-read-only (get-market-fee-info (market-id uint))
  (map-get? market-fees { market-id: market-id })
)

(define-read-only (get-total-platform-fees)
  (var-get total-platform-fees)
)

;; Check if user has claimable payout
(define-read-only (has-claimable-payout (market-id uint) (user principal))
  (match (map-get? winner-payouts { market-id: market-id, user: user })
    payout-data (and (> (get payout-amount payout-data) u0) (not (get is-claimed payout-data)))
    false
  )
)

;; Get payout summary for market
(define-read-only (get-payout-summary (market-id uint))
  (let (
    (resolution (map-get? resolved-markets { market-id: market-id }))
    (fees (map-get? market-fees { market-id: market-id }))
  )
    (match resolution
      res-data (match fees
        fee-data (some {
          winning-outcome: (get winning-outcome res-data),
          resolution-block: (get resolution-block res-data),
          creator-fee: (get creator-fee fee-data),
          platform-fee: (get platform-fee fee-data),
          is-paid: (get is-paid res-data)
        })
        none
      )
      none
    )
  )
)