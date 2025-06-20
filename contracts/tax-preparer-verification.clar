;; Tax Preparer Verification Contract
;; Manages verification and certification of tax preparation professionals

(define-constant CONTRACT_OWNER tx-sender)
(define-constant ERR_UNAUTHORIZED (err u100))
(define-constant ERR_ALREADY_VERIFIED (err u101))
(define-constant ERR_NOT_VERIFIED (err u102))
(define-constant ERR_INVALID_CREDENTIALS (err u103))

;; Data structures
(define-map verified-preparers
  { preparer: principal }
  {
    verified: bool,
    certification-level: uint,
    verification-date: uint,
    expiry-date: uint,
    credentials-hash: (buff 32)
  }
)

(define-map preparer-stats
  { preparer: principal }
  {
    total-clients: uint,
    successful-filings: uint,
    rating: uint
  }
)

;; Public functions
(define-public (verify-preparer (preparer principal) (certification-level uint) (credentials-hash (buff 32)))
  (begin
    (asserts! (is-eq tx-sender CONTRACT_OWNER) ERR_UNAUTHORIZED)
    (asserts! (is-none (map-get? verified-preparers { preparer: preparer })) ERR_ALREADY_VERIFIED)
    (asserts! (> certification-level u0) ERR_INVALID_CREDENTIALS)

    (map-set verified-preparers
      { preparer: preparer }
      {
        verified: true,
        certification-level: certification-level,
        verification-date: block-height,
        expiry-date: (+ block-height u52560), ;; ~1 year in blocks
        credentials-hash: credentials-hash
      }
    )
    (ok true)
  )
)

(define-public (update-preparer-stats (preparer principal) (clients uint) (filings uint) (rating uint))
  (begin
    (asserts! (is-verified preparer) ERR_NOT_VERIFIED)
    (map-set preparer-stats
      { preparer: preparer }
      {
        total-clients: clients,
        successful-filings: filings,
        rating: rating
      }
    )
    (ok true)
  )
)

;; Read-only functions
(define-read-only (is-verified (preparer principal))
  (match (map-get? verified-preparers { preparer: preparer })
    verification-data (and
      (get verified verification-data)
      (< block-height (get expiry-date verification-data))
    )
    false
  )
)

(define-read-only (get-preparer-info (preparer principal))
  (map-get? verified-preparers { preparer: preparer })
)

(define-read-only (get-preparer-stats (preparer principal))
  (map-get? preparer-stats { preparer: preparer })
)
