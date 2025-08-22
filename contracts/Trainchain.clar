

(define-non-fungible-token apprenticeship-credential uint)

(define-constant CONTRACT_OWNER tx-sender)
(define-constant ERR_UNAUTHORIZED (err u100))
(define-constant ERR_NOT_FOUND (err u101))
(define-constant ERR_ALREADY_EXISTS (err u102))
(define-constant ERR_INVALID_PARAMETERS (err u103))
(define-constant ERR_NOT_MENTOR (err u104))
(define-constant ERR_CREDENTIAL_COMPLETED (err u105))

(define-data-var last-token-id uint u0)
(define-data-var contract-uri (optional (string-ascii 256)) none)

(define-map credentials
  uint
  {
    apprentice: principal,
    mentor: principal,
    skill-area: (string-ascii 64),
    institution: (string-ascii 128),
    start-block: uint,
    completion-block: (optional uint),
    metadata-uri: (string-ascii 256),
    verified: bool,
    grade: (optional (string-ascii 16))
  }
)

(define-map mentors
  principal
  {
    name: (string-ascii 64),
    institution: (string-ascii 128),
    specialization: (string-ascii 64),
    active: bool,
    credentials-issued: uint
  }
)

(define-map institutions
  (string-ascii 128)
  {
    verified: bool,
    admin: principal,
    total-credentials: uint
  }
)

(define-map skill-registry
  (string-ascii 64)
  {
    description: (string-ascii 256),
    category: (string-ascii 32),
    difficulty-level: uint
  }
)

(define-public (get-last-token-id)
  (ok (var-get last-token-id))
)

(define-public (get-token-uri (token-id uint))
  (match (map-get? credentials token-id)
    credential (ok (some (get metadata-uri credential)))
    (err ERR_NOT_FOUND)
  )
)

(define-public (get-owner (token-id uint))
  (match (map-get? credentials token-id)
    credential (ok (some (get apprentice credential)))
    (err ERR_NOT_FOUND)
  )
)

(define-public (transfer (token-id uint) (sender principal) (recipient principal))
  (begin
    (asserts! (is-eq tx-sender sender) ERR_UNAUTHORIZED)
    (nft-transfer? apprenticeship-credential token-id sender recipient)
  )
)

(define-public (register-mentor (name (string-ascii 64)) (institution (string-ascii 128)) (specialization (string-ascii 64)))
  (let ((mentor-data {
    name: name,
    institution: institution,
    specialization: specialization,
    active: true,
    credentials-issued: u0
  }))
    (map-set mentors tx-sender mentor-data)
    (ok true)
  )
)

(define-public (register-institution (institution-name (string-ascii 128)) (admin principal))
  (begin
    (asserts! (is-eq tx-sender CONTRACT_OWNER) ERR_UNAUTHORIZED)
    (map-set institutions institution-name {
      verified: true,
      admin: admin,
      total-credentials: u0
    })
    (ok true)
  )
)

(define-public (register-skill (skill-name (string-ascii 64)) (description (string-ascii 256)) (category (string-ascii 32)) (difficulty uint))
  (begin
    (asserts! (is-eq tx-sender CONTRACT_OWNER) ERR_UNAUTHORIZED)
    (map-set skill-registry skill-name {
      description: description,
      category: category,
      difficulty-level: difficulty
    })
    (ok true)
  )
)

(define-public (issue-credential (apprentice principal) (skill-area (string-ascii 64)) (institution (string-ascii 128)) (metadata-uri (string-ascii 256)))
  (let (
    (token-id (+ (var-get last-token-id) u1))
    (mentor-info (unwrap! (map-get? mentors tx-sender) ERR_NOT_MENTOR))
    (current-block stacks-block-height)
  )
    (asserts! (get active mentor-info) ERR_NOT_MENTOR)
    (asserts! (is-eq (get institution mentor-info) institution) ERR_UNAUTHORIZED)
    
    (try! (nft-mint? apprenticeship-credential token-id apprentice))
    
    (map-set credentials token-id {
      apprentice: apprentice,
      mentor: tx-sender,
      skill-area: skill-area,
      institution: institution,
      start-block: current-block,
      completion-block: none,
      metadata-uri: metadata-uri,
      verified: false,
      grade: none
    })
    
    (map-set mentors tx-sender (merge mentor-info {
      credentials-issued: (+ (get credentials-issued mentor-info) u1)
    }))
    
    (var-set last-token-id token-id)
    (ok token-id)
  )
)

(define-public (complete-credential (token-id uint) (grade (string-ascii 16)))
  (let ((credential (unwrap! (map-get? credentials token-id) ERR_NOT_FOUND)))
    (asserts! (is-eq tx-sender (get mentor credential)) ERR_UNAUTHORIZED)
    (asserts! (is-none (get completion-block credential)) ERR_CREDENTIAL_COMPLETED)
    
    (map-set credentials token-id (merge credential {
      completion-block: (some stacks-block-height),
      verified: true,
      grade: (some grade)
    }))
    
    (match (map-get? institutions (get institution credential))
      inst-data (map-set institutions (get institution credential) 
        (merge inst-data {
          total-credentials: (+ (get total-credentials inst-data) u1)
        }))
      true
    )
    
    (ok true)
  )
)

(define-public (verify-credential (token-id uint))
  (let ((credential (unwrap! (map-get? credentials token-id) ERR_NOT_FOUND)))
    (match (map-get? institutions (get institution credential))
      inst-data (begin
        (asserts! (is-eq tx-sender (get admin inst-data)) ERR_UNAUTHORIZED)
        (map-set credentials token-id (merge credential { verified: true }))
        (ok true)
      )
      ERR_NOT_FOUND
    )
  )
)

(define-public (update-mentor-status (mentor principal) (active bool))
  (let ((mentor-data (unwrap! (map-get? mentors mentor) ERR_NOT_FOUND)))
    (asserts! (is-eq tx-sender CONTRACT_OWNER) ERR_UNAUTHORIZED)
    (map-set mentors mentor (merge mentor-data { active: active }))
    (ok true)
  )
)

(define-read-only (get-credential (token-id uint))
  (map-get? credentials token-id)
)

(define-read-only (get-mentor-info (mentor principal))
  (map-get? mentors mentor)
)

(define-read-only (get-institution-info (institution (string-ascii 128)))
  (map-get? institutions institution)
)

(define-read-only (get-skill-info (skill (string-ascii 64)))
  (map-get? skill-registry skill)
)

(define-read-only (is-credential-verified (token-id uint))
  (match (map-get? credentials token-id)
    credential (ok (get verified credential))
    (err ERR_NOT_FOUND)
  )
)

(define-read-only (is-credential-completed (token-id uint))
  (match (map-get? credentials token-id)
    credential (ok (is-some (get completion-block credential)))
    (err ERR_NOT_FOUND)
  )
)

(define-read-only (get-apprentice-credentials (apprentice principal))
  (let ((tokens (list)))
    (fold check-apprentice-token (list u1 u2 u3 u4 u5 u6 u7 u8 u9 u10) tokens)
  )
)

(define-read-only (get-mentor-credentials (mentor principal))
  (let ((tokens (list)))
    (fold check-mentor-token (list u1 u2 u3 u4 u5 u6 u7 u8 u9 u10) tokens)
  )
)

(define-private (check-apprentice-token (token-id uint) (acc (list 10 uint)))
  (match (map-get? credentials token-id)
    credential (if (is-eq (get apprentice credential) tx-sender)
      (unwrap-panic (as-max-len? (append acc token-id) u10))
      acc)
    acc
  )
)

(define-private (check-mentor-token (token-id uint) (acc (list 10 uint)))
  (match (map-get? credentials token-id)
    credential (if (is-eq (get mentor credential) tx-sender)
      (unwrap-panic (as-max-len? (append acc token-id) u10))
      acc)
    acc
  )
)

(define-read-only (get-credential-duration (token-id uint))
  (match (map-get? credentials token-id)
    credential (match (get completion-block credential)
      completion-block (ok (- completion-block (get start-block credential)))
      (ok (- stacks-block-height (get start-block credential)))
    )
    (err ERR_NOT_FOUND)
  )
)
