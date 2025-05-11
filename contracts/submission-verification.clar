;; Submission Verification Contract
;; Records timely filing with authorities

(define-data-var admin principal tx-sender)

;; Map to store regulatory authorities
(define-map authorities uint
  {
    name: (string-utf8 100),
    description: (string-utf8 500),
    verification-key: (buff 33)
  }
)

;; Map to store submission records
(define-map submissions { entity: principal, report-id: uint, authority-id: uint }
  {
    submission-hash: (buff 32),
    submission-date: uint,
    confirmation-hash: (optional (buff 32)),
    status: (string-utf8 20)
  }
)

;; Counter for authority IDs
(define-data-var authority-id-counter uint u1)

;; Public function to add a regulatory authority (only admin)
(define-public (add-authority
                (name (string-utf8 100))
                (description (string-utf8 500))
                (verification-key (buff 33)))
  (let ((new-id (var-get authority-id-counter)))
    (asserts! (is-eq tx-sender (var-get admin)) (err u403))

    (map-set authorities new-id
      {
        name: name,
        description: description,
        verification-key: verification-key
      }
    )
    (var-set authority-id-counter (+ new-id u1))
    (ok new-id)
  )
)

;; Public function to record a submission
(define-public (record-submission
                (report-id uint)
                (authority-id uint)
                (submission-hash (buff 32)))
  (begin
    (asserts! (is-some (map-get? authorities authority-id)) (err u404))

    (map-set submissions { entity: tx-sender, report-id: report-id, authority-id: authority-id }
      {
        submission-hash: submission-hash,
        submission-date: block-height,
        confirmation-hash: none,
        status: u"submitted"
      }
    )
    (ok true)
  )
)

;; Public function to confirm a submission (only admin)
(define-public (confirm-submission
                (entity principal)
                (report-id uint)
                (authority-id uint)
                (confirmation-hash (buff 32)))
  (let ((submission (map-get? submissions { entity: entity, report-id: report-id, authority-id: authority-id })))
    (asserts! (is-eq tx-sender (var-get admin)) (err u403))
    (asserts! (is-some submission) (err u404))

    (map-set submissions { entity: entity, report-id: report-id, authority-id: authority-id }
      (merge (unwrap-panic submission)
        {
          confirmation-hash: (some confirmation-hash),
          status: u"confirmed"
        }
      )
    )
    (ok true)
  )
)

;; Public function to get authority details
(define-read-only (get-authority-details (authority-id uint))
  (map-get? authorities authority-id)
)

;; Public function to get submission details
(define-read-only (get-submission-details (entity principal) (report-id uint) (authority-id uint))
  (map-get? submissions { entity: entity, report-id: report-id, authority-id: authority-id })
)

;; Public function to check if a submission is confirmed
(define-read-only (is-submission-confirmed (entity principal) (report-id uint) (authority-id uint))
  (let ((submission (map-get? submissions { entity: entity, report-id: report-id, authority-id: authority-id })))
    (and
      (is-some submission)
      (is-some (get confirmation-hash (unwrap-panic submission)))
      (is-eq (get status (unwrap-panic submission)) u"confirmed")
    )
  )
)
