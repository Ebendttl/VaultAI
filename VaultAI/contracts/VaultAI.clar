;; AI-Based Decentralized File Storage Marketplace
;; This contract facilitates a marketplace where storage providers can list their services
;; and users can purchase storage space with AI-based file classification and pricing.

;; Constants
(define-constant contract-owner tx-sender)
(define-constant err-not-authorized (err u1))
(define-constant err-provider-not-found (err u2))
(define-constant err-insufficient-funds (err u3))
(define-constant err-invalid-storage-amount (err u4))
(define-constant err-invalid-duration (err u5))
(define-constant err-not-provider (err u6))
(define-constant err-storage-not-available (err u7))
(define-constant err-invalid-ai-class (err u8))
(define-constant err-unwrap-failed (err u9))

;; Data structures
(define-map storage-providers
  { provider: principal }
  {
    available-storage: uint,
    price-per-gb: uint,
    reputation-score: uint,
    total-clients: uint,
    online: bool
  }
)

(define-map storage-contracts
  { contract-id: uint }
  {
    provider: principal,
    client: principal,
    storage-amount: uint,
    duration-days: uint,
    price-paid: uint,
    start-time: uint,
    ai-classification: (string-ascii 20),
    encryption-level: uint,
    active: bool
  }
)

(define-map client-files
  { client: principal, file-id: uint }
  {
    file-hash: (buff 32),
    size-kb: uint,
    ai-classification: (string-ascii 20),
    contract-id: uint,
    encryption-level: uint
  }
)

(define-map ai-pricing-modifiers
  { classification: (string-ascii 20) }
  { price-multiplier: uint }
)

;; Data variables
(define-data-var contract-counter uint u0)

;; Register as a storage provider
(define-public (register-provider (available-storage uint) (price-per-gb uint))
  (begin
    (asserts! (> available-storage u0) err-invalid-storage-amount)
    (ok (map-set storage-providers
      { provider: tx-sender }
      {
        available-storage: available-storage,
        price-per-gb: price-per-gb,
        reputation-score: u100,
        total-clients: u0,
        online: true
      }
    ))
  )
)

;; Update provider information
(define-public (update-provider-info (available-storage uint) (price-per-gb uint) (online bool))
  (let ((provider-data (unwrap! (map-get? storage-providers { provider: tx-sender }) err-not-provider)))
    (ok (map-set storage-providers
      { provider: tx-sender }
      (merge provider-data {
        available-storage: available-storage,
        price-per-gb: price-per-gb,
        online: online
      })
    ))
  )
)

;; Set AI classification pricing modifiers
(define-public (set-ai-pricing-modifier (classification (string-ascii 20)) (multiplier uint))
  (begin
    (asserts! (is-eq tx-sender contract-owner) err-not-authorized)
    (ok (map-set ai-pricing-modifiers
      { classification: classification }
      { price-multiplier: multiplier }
    ))
  )
)

;; Calculate price based on AI classification
(define-read-only (calculate-price (provider principal) (storage-amount uint) (duration-days uint) (ai-classification (string-ascii 20)))
  (begin
    (let ((provider-data (map-get? storage-providers { provider: provider })))
      (if (is-none provider-data)
          err-provider-not-found
          (let ((provider-info (unwrap-panic provider-data)))
            (let ((modifier-data (default-to { price-multiplier: u100 }
                            (map-get? ai-pricing-modifiers { classification: ai-classification }))))
              (let ((base-price (* (get price-per-gb provider-info) storage-amount)))
                (let ((time-factor (/ (* duration-days u100) u30)))
                  (let ((ai-factor (/ (* base-price (get price-multiplier modifier-data)) u100)))
                    (ok (/ (* ai-factor time-factor) u100))
                  )
                )
              )
            )
          )
      )
    )
  )
)

;; Purchase storage from a provider
(define-public (purchase-storage (provider principal) (storage-amount uint) (duration-days uint) (file-hash (buff 32)) (ai-classification (string-ascii 20)) (encryption-level uint))
  (begin
    (let ((provider-data (unwrap! (map-get? storage-providers { provider: provider }) err-provider-not-found)))
      (let ((ai-modifier (map-get? ai-pricing-modifiers { classification: ai-classification })))
        (let ((price-response (calculate-price provider storage-amount duration-days ai-classification)))
          (let ((price (unwrap! price-response err-unwrap-failed)))
            (let ((contract-id (var-get contract-counter)))
              (let ((current-time (unwrap-panic (get-block-info? time (- block-height u1)))))
                
                ;; Verify all conditions
                (asserts! (get online provider-data) err-storage-not-available)
                (asserts! (>= (get available-storage provider-data) storage-amount) err-storage-not-available)
                (asserts! (> storage-amount u0) err-invalid-storage-amount)
                (asserts! (> duration-days u0) err-invalid-duration)
                (asserts! (is-some ai-modifier) err-invalid-ai-class)
                
                ;; Transfer STX from client to provider
                (try! (stx-transfer? price tx-sender provider))
                
                ;; Update the storage provider data
                (map-set storage-providers
                  { provider: provider }
                  (merge provider-data {
                    available-storage: (- (get available-storage provider-data) storage-amount),
                    total-clients: (+ (get total-clients provider-data) u1)
                  })
                )
                
                ;; Create storage contract
                (map-set storage-contracts
                  { contract-id: contract-id }
                  {
                    provider: provider,
                    client: tx-sender,
                    storage-amount: storage-amount,
                    duration-days: duration-days,
                    price-paid: price,
                    start-time: current-time,
                    ai-classification: ai-classification,
                    encryption-level: encryption-level,
                    active: true
                  }
                )
                
                ;; Add file to client's files
                (map-set client-files
                  { client: tx-sender, file-id: contract-id }
                  {
                    file-hash: file-hash,
                    size-kb: (* storage-amount u1024000),  ;; Convert GB to KB
                    ai-classification: ai-classification,
                    contract-id: contract-id,
                    encryption-level: encryption-level
                  }
                )
                
                ;; Increment contract counter
                (var-set contract-counter (+ contract-id u1))
                
                (ok contract-id)
              )
            )
          )
        )
      )
    )
  )
)

;; Terminate a storage contract
(define-public (terminate-storage-contract (contract-id uint))
  (let (
    (contract-data (unwrap! (map-get? storage-contracts { contract-id: contract-id }) err-provider-not-found))
    (provider-data (unwrap! (map-get? storage-providers { provider: (get provider contract-data) }) err-provider-not-found))
  )
    (asserts! (or (is-eq tx-sender (get client contract-data)) (is-eq tx-sender (get provider contract-data))) err-not-authorized)
    
    ;; Update contract status
    (map-set storage-contracts
      { contract-id: contract-id }
      (merge contract-data { active: false })
    )
    
    ;; Return storage to provider's available pool
    (map-set storage-providers
      { provider: (get provider contract-data) }
      (merge provider-data {
        available-storage: (+ (get available-storage provider-data) (get storage-amount contract-data))
      })
    )
    
    (ok true)
  )
)

