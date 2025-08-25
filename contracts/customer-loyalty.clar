;; Customer Loyalty Contract
;; Manages customer profiles, loyalty points, and rewards

;; Constants
(define-constant CONTRACT-OWNER tx-sender)
(define-constant ERR-NOT-AUTHORIZED (err u300))
(define-constant ERR-CUSTOMER-EXISTS (err u301))
(define-constant ERR-CUSTOMER-NOT-FOUND (err u302))
(define-constant ERR-INSUFFICIENT-POINTS (err u303))
(define-constant ERR-INVALID-INPUT (err u304))
(define-constant ERR-REWARD-NOT-FOUND (err u305))

;; Data Variables
(define-data-var next-customer-id uint u1)
(define-data-var next-reward-id uint u1)
(define-data-var points-per-dollar uint u10)

;; Data Maps
(define-map customers
  { customer-id: uint }
  {
    principal: principal,
    name: (string-ascii 100),
    email: (string-ascii 100),
    points-balance: uint,
    total-purchases: uint,
    registration-date: uint,
    last-purchase: (optional uint)
  }
)

(define-map customer-principals
  { principal: principal }
  { customer-id: uint }
)

(define-map rewards
  { reward-id: uint }
  {
    name: (string-ascii 100),
    description: (string-ascii 300),
    points-cost: uint,
    available-quantity: uint,
    active: bool,
    created-date: uint
  }
)

(define-map reward-redemptions
  { customer-id: uint, redemption-id: uint }
  {
    reward-id: uint,
    redeemed-at: uint,
    points-spent: uint,
    status: (string-ascii 20)
  }
)

(define-data-var next-redemption-id uint u1)

(define-map purchase-history
  { customer-id: uint, purchase-id: uint }
  {
    vendor-id: uint,
    amount: uint,
    points-earned: uint,
    purchase-date: uint,
    items: (list 10 (string-ascii 100))
  }
)

(define-data-var next-purchase-id uint u1)

;; Public Functions

;; Register as customer
(define-public (register-customer (name (string-ascii 100)) (email (string-ascii 100)))
  (let ((customer-id (var-get next-customer-id))
        (customer-principal tx-sender))
    (asserts! (is-none (map-get? customer-principals { principal: customer-principal })) ERR-CUSTOMER-EXISTS)
    (asserts! (> (len name) u0) ERR-INVALID-INPUT)
    (asserts! (> (len email) u0) ERR-INVALID-INPUT)

    (map-set customers
      { customer-id: customer-id }
      {
        principal: customer-principal,
        name: name,
        email: email,
        points-balance: u0,
        total-purchases: u0,
        registration-date: block-height,
        last-purchase: none
      }
    )

    (map-set customer-principals
      { principal: customer-principal }
      { customer-id: customer-id }
    )

    (var-set next-customer-id (+ customer-id u1))
    (ok customer-id)
  )
)

;; Award points for purchase
(define-public (award-points (customer-principal principal)
                            (vendor-id uint)
                            (purchase-amount uint)
                            (items (list 10 (string-ascii 100))))
  (let ((customer-info (unwrap! (map-get? customer-principals { principal: customer-principal }) ERR-CUSTOMER-NOT-FOUND))
        (customer-id (get customer-id customer-info))
        (customer-data (unwrap! (map-get? customers { customer-id: customer-id }) ERR-CUSTOMER-NOT-FOUND))
        (points-earned (* purchase-amount (var-get points-per-dollar)))
        (purchase-id (var-get next-purchase-id)))

    (asserts! (is-eq tx-sender CONTRACT-OWNER) ERR-NOT-AUTHORIZED)
    (asserts! (> purchase-amount u0) ERR-INVALID-INPUT)

    ;; Update customer points and purchase total
    (map-set customers
      { customer-id: customer-id }
      (merge customer-data {
        points-balance: (+ (get points-balance customer-data) points-earned),
        total-purchases: (+ (get total-purchases customer-data) purchase-amount),
        last-purchase: (some block-height)
      })
    )

    ;; Record purchase history
    (map-set purchase-history
      { customer-id: customer-id, purchase-id: purchase-id }
      {
        vendor-id: vendor-id,
        amount: purchase-amount,
        points-earned: points-earned,
        purchase-date: block-height,
        items: items
      }
    )

    (var-set next-purchase-id (+ purchase-id u1))
    (ok points-earned)
  )
)

;; Create reward (admin only)
(define-public (create-reward (name (string-ascii 100))
                             (description (string-ascii 300))
                             (points-cost uint)
                             (available-quantity uint))
  (let ((reward-id (var-get next-reward-id)))
    (asserts! (is-eq tx-sender CONTRACT-OWNER) ERR-NOT-AUTHORIZED)
    (asserts! (> (len name) u0) ERR-INVALID-INPUT)
    (asserts! (> points-cost u0) ERR-INVALID-INPUT)

    (map-set rewards
      { reward-id: reward-id }
      {
        name: name,
        description: description,
        points-cost: points-cost,
        available-quantity: available-quantity,
        active: true,
        created-date: block-height
      }
    )

    (var-set next-reward-id (+ reward-id u1))
    (ok reward-id)
  )
)

;; Redeem reward
(define-public (redeem-reward (reward-id uint))
  (let ((customer-info (unwrap! (map-get? customer-principals { principal: tx-sender }) ERR-CUSTOMER-NOT-FOUND))
        (customer-id (get customer-id customer-info))
        (customer-data (unwrap! (map-get? customers { customer-id: customer-id }) ERR-CUSTOMER-NOT-FOUND))
        (reward-data (unwrap! (map-get? rewards { reward-id: reward-id }) ERR-REWARD-NOT-FOUND))
        (redemption-id (var-get next-redemption-id)))

    (asserts! (get active reward-data) ERR-REWARD-NOT-FOUND)
    (asserts! (> (get available-quantity reward-data) u0) ERR-REWARD-NOT-FOUND)
    (asserts! (>= (get points-balance customer-data) (get points-cost reward-data)) ERR-INSUFFICIENT-POINTS)

    ;; Deduct points from customer
    (map-set customers
      { customer-id: customer-id }
      (merge customer-data {
        points-balance: (- (get points-balance customer-data) (get points-cost reward-data))
      })
    )

    ;; Reduce reward quantity
    (map-set rewards
      { reward-id: reward-id }
      (merge reward-data {
        available-quantity: (- (get available-quantity reward-data) u1)
      })
    )

    ;; Record redemption
    (map-set reward-redemptions
      { customer-id: customer-id, redemption-id: redemption-id }
      {
        reward-id: reward-id,
        redeemed-at: block-height,
        points-spent: (get points-cost reward-data),
        status: "pending"
      }
    )

    (var-set next-redemption-id (+ redemption-id u1))
    (ok redemption-id)
  )
)

;; Set points per dollar rate (admin only)
(define-public (set-points-rate (new-rate uint))
  (begin
    (asserts! (is-eq tx-sender CONTRACT-OWNER) ERR-NOT-AUTHORIZED)
    (asserts! (> new-rate u0) ERR-INVALID-INPUT)
    (var-set points-per-dollar new-rate)
    (ok new-rate)
  )
)

;; Read-only Functions

;; Get customer information
(define-read-only (get-customer (customer-id uint))
  (map-get? customers { customer-id: customer-id })
)

;; Get customer by principal
(define-read-only (get-customer-by-principal (principal principal))
  (match (map-get? customer-principals { principal: principal })
    customer-info (map-get? customers { customer-id: (get customer-id customer-info) })
    none
  )
)

;; Get reward information
(define-read-only (get-reward (reward-id uint))
  (map-get? rewards { reward-id: reward-id })
)

;; Get customer points balance
(define-read-only (get-points-balance (customer-principal principal))
  (match (get-customer-by-principal customer-principal)
    customer-data (some (get points-balance customer-data))
    none
  )
)

;; Get purchase history
(define-read-only (get-purchase (customer-id uint) (purchase-id uint))
  (map-get? purchase-history { customer-id: customer-id, purchase-id: purchase-id })
)

;; Get redemption record
(define-read-only (get-redemption (customer-id uint) (redemption-id uint))
  (map-get? reward-redemptions { customer-id: customer-id, redemption-id: redemption-id })
)

;; Get current points rate
(define-read-only (get-points-rate)
  (var-get points-per-dollar)
)
