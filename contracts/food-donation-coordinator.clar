;; Restaurant Food Surplus Donation - Food Donation Coordinator
;; Match surplus food with recipients, coordinate pickup logistics, track donations, ensure food safety, and measure impact

;; Constants
(define-constant contract-owner tx-sender)
(define-constant err-not-found (err u101))
(define-constant err-unauthorized (err u102))
(define-constant err-invalid-input (err u103))
(define-constant err-already-exists (err u104))
(define-constant err-expired (err u105))
(define-constant err-capacity-exceeded (err u106))
(define-constant err-invalid-status (err u107))

;; Data Variables
(define-data-var restaurant-nonce uint u0)
(define-data-var recipient-nonce uint u0)
(define-data-var food-nonce uint u0)
(define-data-var donation-nonce uint u0)
(define-data-var total-food-donated uint u0)
(define-data-var total-meals-provided uint u0)
(define-data-var total-waste-prevented uint u0)

;; Data Maps
(define-map restaurants
  { restaurant-id: uint }
  {
    principal: principal,
    name: (string-utf8 200),
    location: (string-utf8 300),
    contact: (string-utf8 100),
    total-donations: uint,
    food-safety-cert: bool,
    verified: bool,
    registered-at: uint
  }
)

(define-map recipients
  { recipient-id: uint }
  {
    principal: principal,
    name: (string-utf8 200),
    org-type: (string-ascii 50),
    location: (string-utf8 300),
    contact: (string-utf8 100),
    capacity: uint,
    current-inventory: uint,
    people-served: uint,
    verified: bool,
    registered-at: uint
  }
)

(define-map food-listings
  { food-id: uint }
  {
    restaurant-id: uint,
    food-type: (string-utf8 100),
    quantity: uint,
    unit: (string-ascii 20),
    prepared-time: uint,
    expiry-time: uint,
    pickup-start: uint,
    pickup-end: uint,
    temperature: (optional int),
    status: (string-ascii 20),
    description: (string-utf8 500),
    listed-at: uint
  }
)

(define-map donations
  { donation-id: uint }
  {
    food-id: uint,
    restaurant-id: uint,
    recipient-id: uint,
    quantity: uint,
    scheduled-pickup: uint,
    actual-pickup: (optional uint),
    status: (string-ascii 20),
    pickup-confirmed: bool,
    completed-at: (optional uint),
    meals-provided: uint,
    notes: (optional (string-utf8 500))
  }
)

(define-map restaurant-principals
  { principal: principal }
  { restaurant-id: uint }
)

(define-map recipient-principals
  { principal: principal }
  { recipient-id: uint }
)

(define-map food-safety-logs
  { food-id: uint, log-id: uint }
  {
    temperature: int,
    recorded-by: principal,
    recorded-at: uint,
    notes: (string-utf8 200)
  }
)

(define-map safety-log-counter
  { food-id: uint }
  { count: uint }
)

(define-map donation-feedback
  { donation-id: uint }
  {
    rating: uint,
    food-quality: uint,
    timeliness: uint,
    comments: (string-utf8 500),
    submitted-by: principal,
    submitted-at: uint
  }
)

;; Read-only functions
(define-read-only (get-restaurant (restaurant-id uint))
  (map-get? restaurants { restaurant-id: restaurant-id })
)

(define-read-only (get-recipient (recipient-id uint))
  (map-get? recipients { recipient-id: recipient-id })
)

(define-read-only (get-food-listing (food-id uint))
  (map-get? food-listings { food-id: food-id })
)

(define-read-only (get-donation (donation-id uint))
  (map-get? donations { donation-id: donation-id })
)

(define-read-only (get-restaurant-by-principal (principal-addr principal))
  (map-get? restaurant-principals { principal: principal-addr })
)

(define-read-only (get-recipient-by-principal (principal-addr principal))
  (map-get? recipient-principals { principal: principal-addr })
)

(define-read-only (get-safety-log (food-id uint) (log-id uint))
  (map-get? food-safety-logs { food-id: food-id, log-id: log-id })
)

(define-read-only (get-donation-feedback-data (donation-id uint))
  (map-get? donation-feedback { donation-id: donation-id })
)

(define-read-only (get-system-metrics)
  (ok {
    total-food-donated: (var-get total-food-donated),
    total-meals-provided: (var-get total-meals-provided),
    total-waste-prevented: (var-get total-waste-prevented),
    total-restaurants: (var-get restaurant-nonce),
    total-recipients: (var-get recipient-nonce),
    total-donations: (var-get donation-nonce)
  })
)

(define-read-only (get-restaurant-stats (restaurant-id uint))
  (let
    ((restaurant-data (unwrap! (map-get? restaurants { restaurant-id: restaurant-id }) err-not-found)))
    (ok {
      total-donations: (get total-donations restaurant-data),
      verified: (get verified restaurant-data),
      food-safety-cert: (get food-safety-cert restaurant-data),
      name: (get name restaurant-data)
    })
  )
)

(define-read-only (get-recipient-stats (recipient-id uint))
  (let
    ((recipient-data (unwrap! (map-get? recipients { recipient-id: recipient-id }) err-not-found)))
    (ok {
      people-served: (get people-served recipient-data),
      capacity: (get capacity recipient-data),
      current-inventory: (get current-inventory recipient-data),
      capacity-available: (- (get capacity recipient-data) (get current-inventory recipient-data)),
      verified: (get verified recipient-data)
    })
  )
)

(define-read-only (is-food-available (food-id uint))
  (match (map-get? food-listings { food-id: food-id })
    food-data (ok (and
      (is-eq (get status food-data) "available")
      (< block-height (get pickup-end food-data))
    ))
    (ok false)
  )
)

;; Administrative functions
(define-public (verify-restaurant (restaurant-id uint))
  (let
    ((restaurant-data (unwrap! (map-get? restaurants { restaurant-id: restaurant-id }) err-not-found)))
    (asserts! (is-eq tx-sender contract-owner) err-unauthorized)
    (ok (map-set restaurants
      { restaurant-id: restaurant-id }
      (merge restaurant-data { verified: true })
    ))
  )
)

(define-public (verify-recipient (recipient-id uint))
  (let
    ((recipient-data (unwrap! (map-get? recipients { recipient-id: recipient-id }) err-not-found)))
    (asserts! (is-eq tx-sender contract-owner) err-unauthorized)
    (ok (map-set recipients
      { recipient-id: recipient-id }
      (merge recipient-data { verified: true })
    ))
  )
)

(define-public (certify-food-safety (restaurant-id uint))
  (let
    ((restaurant-data (unwrap! (map-get? restaurants { restaurant-id: restaurant-id }) err-not-found)))
    (asserts! (is-eq tx-sender contract-owner) err-unauthorized)
    (ok (map-set restaurants
      { restaurant-id: restaurant-id }
      (merge restaurant-data { food-safety-cert: true })
    ))
  )
)

;; Restaurant Management Functions
(define-public (register-restaurant
  (name (string-utf8 200))
  (location (string-utf8 300))
  (contact (string-utf8 100))
)
  (let
    ((restaurant-id (var-get restaurant-nonce)))
    (asserts! (is-none (map-get? restaurant-principals { principal: tx-sender })) err-already-exists)
    (map-set restaurants
      { restaurant-id: restaurant-id }
      {
        principal: tx-sender,
        name: name,
        location: location,
        contact: contact,
        total-donations: u0,
        food-safety-cert: false,
        verified: false,
        registered-at: block-height
      }
    )
    (map-set restaurant-principals
      { principal: tx-sender }
      { restaurant-id: restaurant-id }
    )
    (var-set restaurant-nonce (+ restaurant-id u1))
    (ok restaurant-id)
  )
)

(define-public (list-surplus-food
  (food-type (string-utf8 100))
  (quantity uint)
  (unit (string-ascii 20))
  (prepared-time uint)
  (expiry-time uint)
  (pickup-start uint)
  (pickup-end uint)
  (description (string-utf8 500))
)
  (let
    (
      (restaurant-lookup (unwrap! (map-get? restaurant-principals { principal: tx-sender }) err-not-found))
      (restaurant-id (get restaurant-id restaurant-lookup))
      (restaurant-data (unwrap! (map-get? restaurants { restaurant-id: restaurant-id }) err-not-found))
      (food-id (var-get food-nonce))
    )
    (asserts! (get verified restaurant-data) err-unauthorized)
    (asserts! (get food-safety-cert restaurant-data) err-unauthorized)
    (asserts! (> quantity u0) err-invalid-input)
    (asserts! (< pickup-start pickup-end) err-invalid-input)
    (asserts! (< prepared-time expiry-time) err-invalid-input)
    (map-set food-listings
      { food-id: food-id }
      {
        restaurant-id: restaurant-id,
        food-type: food-type,
        quantity: quantity,
        unit: unit,
        prepared-time: prepared-time,
        expiry-time: expiry-time,
        pickup-start: pickup-start,
        pickup-end: pickup-end,
        temperature: none,
        status: "available",
        description: description,
        listed-at: block-height
      }
    )
    (var-set food-nonce (+ food-id u1))
    (ok food-id)
  )
)

(define-public (update-food-status (food-id uint) (new-status (string-ascii 20)))
  (let
    (
      (food-data (unwrap! (map-get? food-listings { food-id: food-id }) err-not-found))
      (restaurant-lookup (unwrap! (map-get? restaurant-principals { principal: tx-sender }) err-not-found))
      (restaurant-id (get restaurant-id restaurant-lookup))
    )
    (asserts! (is-eq restaurant-id (get restaurant-id food-data)) err-unauthorized)
    (ok (map-set food-listings
      { food-id: food-id }
      (merge food-data { status: new-status })
    ))
  )
)

(define-public (cancel-listing (food-id uint))
  (let
    (
      (food-data (unwrap! (map-get? food-listings { food-id: food-id }) err-not-found))
      (restaurant-lookup (unwrap! (map-get? restaurant-principals { principal: tx-sender }) err-not-found))
      (restaurant-id (get restaurant-id restaurant-lookup))
    )
    (asserts! (is-eq restaurant-id (get restaurant-id food-data)) err-unauthorized)
    (asserts! (is-eq (get status food-data) "available") err-invalid-status)
    (ok (map-set food-listings
      { food-id: food-id }
      (merge food-data { status: "cancelled" })
    ))
  )
)

;; Recipient Management Functions
(define-public (register-recipient
  (name (string-utf8 200))
  (org-type (string-ascii 50))
  (location (string-utf8 300))
  (contact (string-utf8 100))
  (capacity uint)
)
  (let
    ((recipient-id (var-get recipient-nonce)))
    (asserts! (is-none (map-get? recipient-principals { principal: tx-sender })) err-already-exists)
    (asserts! (> capacity u0) err-invalid-input)
    (map-set recipients
      { recipient-id: recipient-id }
      {
        principal: tx-sender,
        name: name,
        org-type: org-type,
        location: location,
        contact: contact,
        capacity: capacity,
        current-inventory: u0,
        people-served: u0,
        verified: false,
        registered-at: block-height
      }
    )
    (map-set recipient-principals
      { principal: tx-sender }
      { recipient-id: recipient-id }
    )
    (var-set recipient-nonce (+ recipient-id u1))
    (ok recipient-id)
  )
)

(define-public (update-capacity (new-capacity uint))
  (let
    (
      (recipient-lookup (unwrap! (map-get? recipient-principals { principal: tx-sender }) err-not-found))
      (recipient-id (get recipient-id recipient-lookup))
      (recipient-data (unwrap! (map-get? recipients { recipient-id: recipient-id }) err-not-found))
    )
    (asserts! (>= new-capacity (get current-inventory recipient-data)) err-invalid-input)
    (ok (map-set recipients
      { recipient-id: recipient-id }
      (merge recipient-data { capacity: new-capacity })
    ))
  )
)

(define-public (update-people-served (additional-people uint))
  (let
    (
      (recipient-lookup (unwrap! (map-get? recipient-principals { principal: tx-sender }) err-not-found))
      (recipient-id (get recipient-id recipient-lookup))
      (recipient-data (unwrap! (map-get? recipients { recipient-id: recipient-id }) err-not-found))
    )
    (ok (map-set recipients
      { recipient-id: recipient-id }
      (merge recipient-data { people-served: (+ (get people-served recipient-data) additional-people) })
    ))
  )
)

;; Donation Coordination Functions
(define-public (match-donation
  (food-id uint)
  (recipient-id uint)
  (scheduled-pickup uint)
)
  (let
    (
      (food-data (unwrap! (map-get? food-listings { food-id: food-id }) err-not-found))
      (recipient-data (unwrap! (map-get? recipients { recipient-id: recipient-id }) err-not-found))
      (donation-id (var-get donation-nonce))
      (restaurant-data (unwrap! (map-get? restaurants { restaurant-id: (get restaurant-id food-data) }) err-not-found))
    )
    (asserts! (is-eq tx-sender contract-owner) err-unauthorized)
    (asserts! (get verified recipient-data) err-unauthorized)
    (asserts! (is-eq (get status food-data) "available") err-invalid-status)
    (asserts! (< block-height (get expiry-time food-data)) err-expired)
    (asserts! (<= (get pickup-start food-data) scheduled-pickup) err-invalid-input)
    (asserts! (>= (get pickup-end food-data) scheduled-pickup) err-invalid-input)
    (asserts! (< (get current-inventory recipient-data) (get capacity recipient-data)) err-capacity-exceeded)
    
    (map-set donations
      { donation-id: donation-id }
      {
        food-id: food-id,
        restaurant-id: (get restaurant-id food-data),
        recipient-id: recipient-id,
        quantity: (get quantity food-data),
        scheduled-pickup: scheduled-pickup,
        actual-pickup: none,
        status: "matched",
        pickup-confirmed: false,
        completed-at: none,
        meals-provided: u0,
        notes: none
      }
    )
    
    (map-set food-listings
      { food-id: food-id }
      (merge food-data { status: "matched" })
    )
    
    (map-set recipients
      { recipient-id: recipient-id }
      (merge recipient-data { 
        current-inventory: (+ (get current-inventory recipient-data) (get quantity food-data))
      })
    )
    
    (var-set donation-nonce (+ donation-id u1))
    (ok donation-id)
  )
)

(define-public (confirm-pickup (donation-id uint))
  (let
    (
      (donation-data (unwrap! (map-get? donations { donation-id: donation-id }) err-not-found))
      (recipient-lookup (unwrap! (map-get? recipient-principals { principal: tx-sender }) err-not-found))
      (recipient-id (get recipient-id recipient-lookup))
    )
    (asserts! (is-eq recipient-id (get recipient-id donation-data)) err-unauthorized)
    (asserts! (is-eq (get status donation-data) "matched") err-invalid-status)
    (ok (map-set donations
      { donation-id: donation-id }
      (merge donation-data {
        pickup-confirmed: true,
        actual-pickup: (some block-height),
        status: "in-transit"
      })
    ))
  )
)

(define-public (complete-donation
  (donation-id uint)
  (meals-provided uint)
  (notes (string-utf8 500))
)
  (let
    (
      (donation-data (unwrap! (map-get? donations { donation-id: donation-id }) err-not-found))
      (recipient-lookup (unwrap! (map-get? recipient-principals { principal: tx-sender }) err-not-found))
      (recipient-id (get recipient-id recipient-lookup))
      (restaurant-data (unwrap! (map-get? restaurants { restaurant-id: (get restaurant-id donation-data) }) err-not-found))
    )
    (asserts! (is-eq recipient-id (get recipient-id donation-data)) err-unauthorized)
    (asserts! (is-eq (get status donation-data) "in-transit") err-invalid-status)
    
    (map-set donations
      { donation-id: donation-id }
      (merge donation-data {
        status: "completed",
        completed-at: (some block-height),
        meals-provided: meals-provided,
        notes: (some notes)
      })
    )
    
    (map-set restaurants
      { restaurant-id: (get restaurant-id donation-data) }
      (merge restaurant-data { total-donations: (+ (get total-donations restaurant-data) u1) })
    )
    
    (var-set total-food-donated (+ (var-get total-food-donated) (get quantity donation-data)))
    (var-set total-meals-provided (+ (var-get total-meals-provided) meals-provided))
    (var-set total-waste-prevented (+ (var-get total-waste-prevented) (get quantity donation-data)))
    
    (ok true)
  )
)

;; Food Safety Functions
(define-public (record-temperature
  (food-id uint)
  (temperature int)
  (notes (string-utf8 200))
)
  (let
    (
      (food-data (unwrap! (map-get? food-listings { food-id: food-id }) err-not-found))
      (restaurant-lookup (unwrap! (map-get? restaurant-principals { principal: tx-sender }) err-not-found))
      (restaurant-id (get restaurant-id restaurant-lookup))
      (log-count (default-to { count: u0 } (map-get? safety-log-counter { food-id: food-id })))
      (log-id (get count log-count))
    )
    (asserts! (is-eq restaurant-id (get restaurant-id food-data)) err-unauthorized)
    
    (map-set food-safety-logs
      { food-id: food-id, log-id: log-id }
      {
        temperature: temperature,
        recorded-by: tx-sender,
        recorded-at: block-height,
        notes: notes
      }
    )
    
    (map-set food-listings
      { food-id: food-id }
      (merge food-data { temperature: (some temperature) })
    )
    
    (map-set safety-log-counter
      { food-id: food-id }
      { count: (+ log-id u1) }
    )
    
    (ok log-id)
  )
)

;; Feedback Functions
(define-public (submit-feedback
  (donation-id uint)
  (rating uint)
  (food-quality uint)
  (timeliness uint)
  (comments (string-utf8 500))
)
  (let
    (
      (donation-data (unwrap! (map-get? donations { donation-id: donation-id }) err-not-found))
      (recipient-lookup (unwrap! (map-get? recipient-principals { principal: tx-sender }) err-not-found))
      (recipient-id (get recipient-id recipient-lookup))
    )
    (asserts! (is-eq recipient-id (get recipient-id donation-data)) err-unauthorized)
    (asserts! (is-eq (get status donation-data) "completed") err-invalid-status)
    (asserts! (<= rating u5) err-invalid-input)
    (asserts! (<= food-quality u5) err-invalid-input)
    (asserts! (<= timeliness u5) err-invalid-input)
    
    (ok (map-set donation-feedback
      { donation-id: donation-id }
      {
        rating: rating,
        food-quality: food-quality,
        timeliness: timeliness,
        comments: comments,
        submitted-by: tx-sender,
        submitted-at: block-height
      }
    ))
  )
)

