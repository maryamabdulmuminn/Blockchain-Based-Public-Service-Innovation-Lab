;; Agency Verification Contract
;; Validates government entities and manages their verification status

;; Constants
(define-constant CONTRACT_OWNER tx-sender)
(define-constant ERR_UNAUTHORIZED (err u100))
(define-constant ERR_ALREADY_VERIFIED (err u101))
(define-constant ERR_NOT_FOUND (err u102))
(define-constant ERR_INVALID_DATA (err u103))

;; Data Variables
(define-data-var next-agency-id uint u1)

;; Data Maps
(define-map agencies
  { agency-id: uint }
  {
    name: (string-ascii 100),
    department: (string-ascii 100),
    contact-email: (string-ascii 100),
    verification-date: uint,
    is-active: bool,
    verifier: principal
  }
)

(define-map agency-principals
  { principal: principal }
  { agency-id: uint }
)

;; Public Functions

;; Register a new government agency
(define-public (register-agency (name (string-ascii 100))
                               (department (string-ascii 100))
                               (contact-email (string-ascii 100)))
  (let ((agency-id (var-get next-agency-id)))
    (if (is-eq tx-sender CONTRACT_OWNER)
      (begin
        (map-set agencies
          { agency-id: agency-id }
          {
            name: name,
            department: department,
            contact-email: contact-email,
            verification-date: block-height,
            is-active: true,
            verifier: tx-sender
          }
        )
        (map-set agency-principals
          { principal: tx-sender }
          { agency-id: agency-id }
        )
        (var-set next-agency-id (+ agency-id u1))
        (ok agency-id)
      )
      ERR_UNAUTHORIZED
    )
  )
)

;; Verify an agency's status
(define-public (verify-agency (agency-id uint))
  (let ((agency (unwrap! (map-get? agencies { agency-id: agency-id }) ERR_NOT_FOUND)))
    (if (is-eq tx-sender CONTRACT_OWNER)
      (begin
        (map-set agencies
          { agency-id: agency-id }
          (merge agency { verification-date: block-height })
        )
        (ok true)
      )
      ERR_UNAUTHORIZED
    )
  )
)

;; Deactivate an agency
(define-public (deactivate-agency (agency-id uint))
  (let ((agency (unwrap! (map-get? agencies { agency-id: agency-id }) ERR_NOT_FOUND)))
    (if (is-eq tx-sender CONTRACT_OWNER)
      (begin
        (map-set agencies
          { agency-id: agency-id }
          (merge agency { is-active: false })
        )
        (ok true)
      )
      ERR_UNAUTHORIZED
    )
  )
)

;; Read-only Functions

;; Get agency details
(define-read-only (get-agency (agency-id uint))
  (map-get? agencies { agency-id: agency-id })
)

;; Check if principal is verified agency
(define-read-only (is-verified-agency (principal principal))
  (match (map-get? agency-principals { principal: principal })
    agency-data
    (match (map-get? agencies { agency-id: (get agency-id agency-data) })
      agency (get is-active agency)
      false
    )
    false
  )
)

;; Get total number of agencies
(define-read-only (get-total-agencies)
  (- (var-get next-agency-id) u1)
)
