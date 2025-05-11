;; Requirement Tracking Contract
;; Records applicable regulations

(define-data-var admin principal tx-sender)

;; Map to store regulatory requirements
(define-map requirements uint
  {
    title: (string-utf8 100),
    description: (string-utf8 500),
    effective-date: uint,
    expiry-date: uint,
    status: (string-utf8 20)
  }
)

;; Map to track which requirements apply to which entities
(define-map entity-requirements { entity: principal, req-id: uint } bool)

;; Counter for requirement IDs
(define-data-var requirement-id-counter uint u1)

;; Public function to add a new requirement (only admin)
(define-public (add-requirement
                (title (string-utf8 100))
                (description (string-utf8 500))
                (effective-date uint)
                (expiry-date uint))
  (let ((new-id (var-get requirement-id-counter)))
    (asserts! (is-eq tx-sender (var-get admin)) (err u403))

    (map-set requirements new-id
      {
        title: title,
        description: description,
        effective-date: effective-date,
        expiry-date: expiry-date,
        status: u"active"
      }
    )
    (var-set requirement-id-counter (+ new-id u1))
    (ok new-id)
  )
)

;; Public function to assign requirement to entity (only admin)
(define-public (assign-requirement-to-entity (entity principal) (req-id uint))
  (begin
    (asserts! (is-eq tx-sender (var-get admin)) (err u403))
    (asserts! (is-some (map-get? requirements req-id)) (err u404))

    (map-set entity-requirements { entity: entity, req-id: req-id } true)
    (ok true)
  )
)

;; Public function to remove requirement from entity (only admin)
(define-public (remove-requirement-from-entity (entity principal) (req-id uint))
  (begin
    (asserts! (is-eq tx-sender (var-get admin)) (err u403))
    (map-delete entity-requirements { entity: entity, req-id: req-id })
    (ok true)
  )
)

;; Public function to check if a requirement applies to an entity
(define-read-only (is-requirement-applicable (entity principal) (req-id uint))
  (default-to false (map-get? entity-requirements { entity: entity, req-id: req-id }))
)

;; Public function to get requirement details
(define-read-only (get-requirement-details (req-id uint))
  (map-get? requirements req-id)
)

;; Public function to update requirement status (only admin)
(define-public (update-requirement-status (req-id uint) (new-status (string-utf8 20)))
  (let ((requirement (map-get? requirements req-id)))
    (asserts! (is-eq tx-sender (var-get admin)) (err u403))
    (asserts! (is-some requirement) (err u404))

    (map-set requirements req-id (merge (unwrap-panic requirement) { status: new-status }))
    (ok true)
  )
)
