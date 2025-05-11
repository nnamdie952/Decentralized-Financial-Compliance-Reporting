;; Report Generation Contract
;; Creates standardized compliance documents

(define-data-var admin principal tx-sender)

;; Map to store report templates
(define-map report-templates uint
  {
    name: (string-utf8 100),
    description: (string-utf8 500),
    required-data-templates: (list 10 uint)
  }
)

;; Map to store generated reports
(define-map generated-reports { entity: principal, report-template-id: uint }
  {
    report-hash: (buff 32),
    generation-date: uint,
    valid-until: uint,
    status: (string-utf8 20)
  }
)

;; Counter for report template IDs
(define-data-var template-id-counter uint u1)

;; Public function to create a report template (only admin)
(define-public (create-report-template
                (name (string-utf8 100))
                (description (string-utf8 500))
                (required-data-templates (list 10 uint)))
  (let ((new-id (var-get template-id-counter)))
    (asserts! (is-eq tx-sender (var-get admin)) (err u403))

    (map-set report-templates new-id
      {
        name: name,
        description: description,
        required-data-templates: required-data-templates
      }
    )
    (var-set template-id-counter (+ new-id u1))
    (ok new-id)
  )
)

;; Public function to generate a report
(define-public (generate-report (report-template-id uint) (report-hash (buff 32)) (valid-days uint))
  (begin
    (asserts! (is-some (map-get? report-templates report-template-id)) (err u404))

    (map-set generated-reports { entity: tx-sender, report-template-id: report-template-id }
      {
        report-hash: report-hash,
        generation-date: block-height,
        valid-until: (+ block-height valid-days),
        status: u"generated"
      }
    )
    (ok true)
  )
)

;; Public function to verify a report (only admin)
(define-public (verify-report (entity principal) (report-template-id uint) (status (string-utf8 20)))
  (let ((report (map-get? generated-reports { entity: entity, report-template-id: report-template-id })))
    (asserts! (is-eq tx-sender (var-get admin)) (err u403))
    (asserts! (is-some report) (err u404))

    (map-set generated-reports { entity: entity, report-template-id: report-template-id }
      (merge (unwrap-panic report) { status: status })
    )
    (ok true)
  )
)

;; Public function to get report template details
(define-read-only (get-report-template-details (template-id uint))
  (map-get? report-templates template-id)
)

;; Public function to get generated report details
(define-read-only (get-report-details (entity principal) (report-template-id uint))
  (map-get? generated-reports { entity: entity, report-template-id: report-template-id })
)

;; Public function to check if a report is valid
(define-read-only (is-report-valid (entity principal) (report-template-id uint))
  (let ((report (map-get? generated-reports { entity: entity, report-template-id: report-template-id })))
    (and
      (is-some report)
      (< block-height (get valid-until (unwrap-panic report)))
      (is-eq (get status (unwrap-panic report)) u"verified")
    )
  )
)
