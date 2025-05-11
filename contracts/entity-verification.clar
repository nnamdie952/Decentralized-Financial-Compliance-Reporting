;; Entity Verification Contract
;; Validates regulated financial institutions

(define-data-var admin principal tx-sender)

;; Map to store verified entities
(define-map verified-entities principal
  {
    name: (string-utf8 100),
    license-id: (string-utf8 50),
    verification-date: uint,
    status: (string-utf8 20)
  }
)

;; Public function to verify a new entity (only admin)
(define-public (verify-entity (entity principal) (name (string-utf8 100)) (license-id (string-utf8 50)))
  (begin
    (asserts! (is-eq tx-sender (var-get admin)) (err u403))
    (asserts! (is-none (map-get? verified-entities entity)) (err u100))

    (map-set verified-entities entity
      {
        name: name,
        license-id: license-id,
        verification-date: block-height,
        status: u"active"
      }
    )
    (ok true)
  )
)

;; Public function to check if an entity is verified
(define-read-only (is-verified (entity principal))
  (is-some (map-get? verified-entities entity))
)

;; Public function to get entity details
(define-read-only (get-entity-details (entity principal))
  (map-get? verified-entities entity)
)

;; Public function to revoke verification (only admin)
(define-public (revoke-verification (entity principal))
  (begin
    (asserts! (is-eq tx-sender (var-get admin)) (err u403))
    (asserts! (is-some (map-get? verified-entities entity)) (err u404))

    (map-delete verified-entities entity)
    (ok true)
  )
)

;; Public function to update admin (only current admin)
(define-public (update-admin (new-admin principal))
  (begin
    (asserts! (is-eq tx-sender (var-get admin)) (err u403))
    (var-set admin new-admin)
    (ok true)
  )
)
