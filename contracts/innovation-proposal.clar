;; Innovation Proposal Contract
;; Records and manages public service improvement initiatives

;; Constants
(define-constant ERR_UNAUTHORIZED (err u200))
(define-constant ERR_NOT_FOUND (err u201))
(define-constant ERR_INVALID_STATUS (err u202))
(define-constant ERR_INVALID_DATA (err u203))

;; Data Variables
(define-data-var next-proposal-id uint u1)

;; Data Maps
(define-map proposals
  { proposal-id: uint }
  {
    title: (string-ascii 200),
    description: (string-ascii 1000),
    proposer: principal,
    agency-id: uint,
    status: (string-ascii 20),
    created-at: uint,
    updated-at: uint,
    category: (string-ascii 50),
    estimated-cost: uint,
    expected-impact: (string-ascii 500)
  }
)

(define-map proposal-votes
  { proposal-id: uint, voter: principal }
  { vote: bool, voted-at: uint }
)

(define-map proposal-vote-counts
  { proposal-id: uint }
  { yes-votes: uint, no-votes: uint }
)

;; Public Functions

;; Submit a new innovation proposal
(define-public (submit-proposal (title (string-ascii 200))
                               (description (string-ascii 1000))
                               (agency-id uint)
                               (category (string-ascii 50))
                               (estimated-cost uint)
                               (expected-impact (string-ascii 500)))
  (let ((proposal-id (var-get next-proposal-id)))
    (begin
      (map-set proposals
        { proposal-id: proposal-id }
        {
          title: title,
          description: description,
          proposer: tx-sender,
          agency-id: agency-id,
          status: "submitted",
          created-at: block-height,
          updated-at: block-height,
          category: category,
          estimated-cost: estimated-cost,
          expected-impact: expected-impact
        }
      )
      (map-set proposal-vote-counts
        { proposal-id: proposal-id }
        { yes-votes: u0, no-votes: u0 }
      )
      (var-set next-proposal-id (+ proposal-id u1))
      (ok proposal-id)
    )
  )
)

;; Update proposal status
(define-public (update-proposal-status (proposal-id uint) (new-status (string-ascii 20)))
  (let ((proposal (unwrap! (map-get? proposals { proposal-id: proposal-id }) ERR_NOT_FOUND)))
    (if (is-eq tx-sender (get proposer proposal))
      (begin
        (map-set proposals
          { proposal-id: proposal-id }
          (merge proposal {
            status: new-status,
            updated-at: block-height
          })
        )
        (ok true)
      )
      ERR_UNAUTHORIZED
    )
  )
)

;; Vote on a proposal
(define-public (vote-on-proposal (proposal-id uint) (vote bool))
  (let ((proposal (unwrap! (map-get? proposals { proposal-id: proposal-id }) ERR_NOT_FOUND))
        (vote-counts (unwrap! (map-get? proposal-vote-counts { proposal-id: proposal-id }) ERR_NOT_FOUND)))
    (begin
      (map-set proposal-votes
        { proposal-id: proposal-id, voter: tx-sender }
        { vote: vote, voted-at: block-height }
      )
      (if vote
        (map-set proposal-vote-counts
          { proposal-id: proposal-id }
          (merge vote-counts { yes-votes: (+ (get yes-votes vote-counts) u1) })
        )
        (map-set proposal-vote-counts
          { proposal-id: proposal-id }
          (merge vote-counts { no-votes: (+ (get no-votes vote-counts) u1) })
        )
      )
      (ok true)
    )
  )
)

;; Read-only Functions

;; Get proposal details
(define-read-only (get-proposal (proposal-id uint))
  (map-get? proposals { proposal-id: proposal-id })
)

;; Get proposal vote counts
(define-read-only (get-proposal-votes (proposal-id uint))
  (map-get? proposal-vote-counts { proposal-id: proposal-id })
)

;; Check if user has voted
(define-read-only (has-voted (proposal-id uint) (voter principal))
  (is-some (map-get? proposal-votes { proposal-id: proposal-id, voter: voter }))
)

;; Get total proposals
(define-read-only (get-total-proposals)
  (- (var-get next-proposal-id) u1)
)
