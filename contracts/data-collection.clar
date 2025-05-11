;; Data Collection Contract
;; Manages gathering of required information

(define-data-var admin principal tx-sender)

;; Map to store data templates
(define-map data-templates uint
  {
    name: (string-utf8 100),
    fields: (list 10 (string-utf8 50)),
    requirement-id: uint
  }
)

;; Map to store submitted data
(define-map submitted-data { entity: principal, template-id: uint }
  {
    data-hash: (buff 32),
    submission-date: uint,
    status: (string-utf8 20)
  }
)

;; Counter for template IDs
(define-data-var template-id-counter uint u1)

;; Public function to create a data template (only admin)
(define-public (create-data-template
                (name (string-utf8 100))
                (fields (list 10 (string-utf8 50)))
                (requirement-id uint))
  (let ((new-id (var-get template-id-counter)))
    (asserts! (is-eq tx-sender (var-get admin)) (err u403))

    (map-set data-templates new-id
      {
        name: name,
        fields: fields,
        requirement-id: requirement-id
      }
    )
    (var-set template-id-counter (+ new-id u1))
    (ok new-id)
  )
)

;; Public function to submit data
(define-public (submit-data (template-id uint) (data-hash (buff 32)))
  (begin
    (asserts! (is-some (map-get? data-templates template-id)) (err u404))

    (map-set submitted-data { entity: tx-sender, template-id: template-id }
      {
        data-hash: data-hash,
        submission-date: block-height,
        status: u"submitted"
      }
    )
    (ok true)
  )
)

;; Public function to verify submitted data (only admin)
(define-public (verify-data (entity principal) (template-id uint) (status (string-utf8 20)))
  (let ((submission (map-get? submitted-data { entity: entity, template-id: template-id })))
    (asserts! (is-eq tx-sender (var-get admin)) (err u403))
    (asserts! (is-some submission) (err u404))

    (map-set submitted-data { entity: entity, template-id: template-id }
      (merge (unwrap-panic submission) { status: status })
    )
    (ok true)
  )
)

;; Public function to get template details
(define-read-only (get-template-details (template-id uint))
  (map-get? data-templates template-id)
)

;; Public function to get submission details
(define-read-only (get-submission-details (entity principal) (template-id uint))
  (map-get? submitted-data { entity: entity, template-id: template-id })
)
