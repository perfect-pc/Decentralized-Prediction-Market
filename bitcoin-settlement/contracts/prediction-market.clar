;; prediction-market.clar

(define-constant contract-owner tx-sender)

;; Data Maps

;; Stores the amount a user has bet on a specific outcome for a market.
(define-map user-bets
  { market-id: uint, user: principal, outcome: uint }
  { amount: uint }
)

;; Stores the total stake a user has across all outcomes for a market.
(define-map user-total-stakes
  { market-id: uint, user: principal }
  { total-stake: uint }
)

;; Stores the total stake for a specific outcome in a market.
(define-map market-outcome-stakes
  { market-id: uint, outcome: uint }
  { total-stake: uint }
)

;; Stores the total amount staked in a market.
(define-map market-totals
  { market-id: uint }
  { total-staked: uint }
)

;; Stores market details (e.g., creator, end block, outcomes)
(define-map markets
  { market-id: uint }
  { creator: principal, end-block: uint, outcomes: uint }
)

;; Data Variables
(define-data-var market-counter uint u0)

;; Helper Functions

;; Checks if the current block is past the market's end block.
(define-read-only (is-market-closed (market-id uint))
  (let ((market (map-get? markets { market-id: market-id })))
    (if (is-none market)
        false
        (let ((market-data (unwrap-panic market)))
          (>= stacks-block-height (get end-block market-data))
        )
    )
  )
)

;; Public Functions

;; Creates a new prediction market.
(define-public (create-market (end-block uint) (outcomes uint))
  (begin
    (asserts! (> end-block stacks-block-height) (err u400))
    (asserts! (> outcomes u1) (err u401))
    (let ((new-market-id (+ u1 (var-get market-counter))))
      (map-insert markets
        { market-id: new-market-id }
        { creator: contract-owner, end-block: end-block, outcomes: outcomes }
      )
      (var-set market-counter new-market-id)
      (ok new-market-id)
    )
  )
)

;; Places a bet on a specific outcome for a market.
(define-public (place-bet (market-id uint) (outcome uint) (amount uint))
  (begin
    (asserts! (not (is-market-closed market-id)) (err u402))
    (let ((market (map-get? markets { market-id: market-id })))
      (match market
        market-data
        (begin
          (asserts! (and (> amount u0) (<= outcome (get outcomes market-data))) (err u403))
          (let (
           (user-current-bet
  (match (get-user-bet market-id tx-sender outcome)
    bet-data (get amount bet-data)
    u0
  )
)

          (user-current-total
    (match (get-user-total-stake market-id tx-sender)
      stake-data (get total-stake stake-data)
      u0
    )
  )
  (outcome-current-stake
    (match (get-market-outcome-stake market-id outcome)
      stake-data (get total-stake stake-data)
      u0
    )
  )
  (market-total-staked
    (match (get-market-total market-id)
      total-data (get total-staked total-data)
      u0
    )
  )
)
            (map-set user-bets 
              { market-id: market-id, user: tx-sender, outcome: outcome } 
              { amount: (+ amount user-current-bet) }
            )
            (map-set user-total-stakes 
              { market-id: market-id, user: tx-sender } 
              { total-stake: (+ amount user-current-total) }
            )
            (map-set market-outcome-stakes 
              { market-id: market-id, outcome: outcome } 
              { total-stake: (+ amount outcome-current-stake) }
            )
            (map-set market-totals 
              { market-id: market-id } 
              { total-staked: (+ amount market-total-staked) }
            )
            (ok true)
          )
        )
        (err u404)
      )
    )
  )
)

;; Resolves a market and distributes winnings.
(define-public (resolve-market (market-id uint) (winning-outcome uint))
  (begin
    (asserts! (is-market-closed market-id) (err u405))
    (let ((market (map-get? markets { market-id: market-id })))
      (match market
        market-data
        (begin
          (asserts! (<= winning-outcome (get outcomes market-data)) (err u406))
          ;; TODO: Implement payout logic. This is a placeholder.
          (ok true)
        )
        (err u404)
      )
    )
  )
)

;; Read-only functions to get data

(define-read-only (get-market (market-id uint))
  (map-get? markets { market-id: market-id })
)

(define-read-only (get-user-bet (market-id uint) (user principal) (outcome uint))
  (map-get? user-bets { market-id: market-id, user: user, outcome: outcome })
)

(define-read-only (get-user-total-stake (market-id uint) (user principal))
  (map-get? user-total-stakes { market-id: market-id, user: user })
)

(define-read-only (get-market-outcome-stake (market-id uint) (outcome uint))
  (map-get? market-outcome-stakes { market-id: market-id, outcome: outcome })
)

(define-read-only (get-market-total (market-id uint))
  (map-get? market-totals { market-id: market-id })
)
