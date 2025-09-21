
;; title: OracleProvider
;; version: 1.0.0
;; summary: Address reputation system for oracle data accuracy and reliability scoring
;; description: A smart contract that tracks oracle provider reputation based on data accuracy,
;;              submission frequency, and community feedback to ensure reliable oracle data

;; traits
;;

;; token definitions
;;

;; constants
;;
(define-constant CONTRACT_OWNER tx-sender)
(define-constant ERR_UNAUTHORIZED (err u401))
(define-constant ERR_ORACLE_NOT_FOUND (err u404))
(define-constant ERR_INVALID_SCORE (err u400))
(define-constant ERR_ALREADY_REGISTERED (err u409))

;; Minimum and maximum reputation scores
(define-constant MIN_REPUTATION_SCORE u0)
(define-constant MAX_REPUTATION_SCORE u100)

;; data vars
;;
(define-data-var total-oracles uint u0)

;; data maps
;;
;; Main oracle reputation tracking
(define-map oracle-reputation
    { oracle-address: principal }
    {
        reputation-score: uint,
        total-submissions: uint,
        accurate-submissions: uint,
        last-update: uint,
        is-active: bool
    }
)

;; Oracle registration details
(define-map oracle-details
    { oracle-address: principal }
    {
        name: (string-ascii 50),
        description: (string-ascii 200),
        registration-block: uint
    }
)

;; Data submission tracking
(define-map oracle-submissions
    { oracle-address: principal, submission-id: uint }
    {
        data-hash: (buff 32),
        timestamp: uint,
        verified: bool,
        accuracy-score: uint
    }
)

;; Feedback from other users about oracle accuracy
(define-map oracle-feedback
    { oracle-address: principal, feedback-provider: principal }
    {
        rating: uint,
        comment: (string-ascii 100),
        timestamp: uint
    }
)

;; public functions
;;

;; Register a new oracle provider
(define-public (register-oracle (name (string-ascii 50)) (description (string-ascii 200)))
    (let ((oracle-addr tx-sender))
        (asserts! (is-none (map-get? oracle-reputation { oracle-address: oracle-addr })) ERR_ALREADY_REGISTERED)
        (map-set oracle-reputation
            { oracle-address: oracle-addr }
            {
                reputation-score: u50, ;; Start with neutral score
                total-submissions: u0,
                accurate-submissions: u0,
                last-update: block-height,
                is-active: true
            }
        )
        (map-set oracle-details
            { oracle-address: oracle-addr }
            {
                name: name,
                description: description,
                registration-block: block-height
            }
        )
        (var-set total-oracles (+ (var-get total-oracles) u1))
        (ok oracle-addr)
    )
)

;; Submit oracle data (simplified version)
(define-public (submit-data (data-hash (buff 32)))
    (let (
        (oracle-addr tx-sender)
        (current-rep (unwrap! (map-get? oracle-reputation { oracle-address: oracle-addr }) ERR_ORACLE_NOT_FOUND))
    )
        (asserts! (get is-active current-rep) ERR_UNAUTHORIZED)
        (map-set oracle-reputation
            { oracle-address: oracle-addr }
            (merge current-rep {
                total-submissions: (+ (get total-submissions current-rep) u1),
                last-update: block-height
            })
        )
        (ok true)
    )
)

;; Update oracle accuracy after verification (only contract owner can call this)
(define-public (update-oracle-accuracy (oracle-addr principal) (was-accurate bool))
    (let ((current-rep (unwrap! (map-get? oracle-reputation { oracle-address: oracle-addr }) ERR_ORACLE_NOT_FOUND)))
        (asserts! (is-eq tx-sender CONTRACT_OWNER) ERR_UNAUTHORIZED)
        (asserts! (get is-active current-rep) ERR_UNAUTHORIZED)

        (let (
            (new-accurate-count (if was-accurate
                                  (+ (get accurate-submissions current-rep) u1)
                                  (get accurate-submissions current-rep)))
            (total-subs (get total-submissions current-rep))
            (new-score (if (> total-subs u0)
                         (/ (* new-accurate-count u100) total-subs)
                         u50))
        )
            (map-set oracle-reputation
                { oracle-address: oracle-addr }
                (merge current-rep {
                    accurate-submissions: new-accurate-count,
                    reputation-score: new-score,
                    last-update: block-height
                })
            )
            (ok new-score)
        )
    )
)

;; Provide feedback on an oracle (rating from 1-5)
(define-public (provide-feedback (oracle-addr principal) (rating uint) (comment (string-ascii 100)))
    (begin
        (asserts! (and (>= rating u1) (<= rating u5)) ERR_INVALID_SCORE)
        (asserts! (is-some (map-get? oracle-reputation { oracle-address: oracle-addr })) ERR_ORACLE_NOT_FOUND)
        (map-set oracle-feedback
            { oracle-address: oracle-addr, feedback-provider: tx-sender }
            {
                rating: rating,
                comment: comment,
                timestamp: block-height
            }
        )
        (ok true)
    )
)

;; Deactivate an oracle (only contract owner)
(define-public (deactivate-oracle (oracle-addr principal))
    (let ((current-rep (unwrap! (map-get? oracle-reputation { oracle-address: oracle-addr }) ERR_ORACLE_NOT_FOUND)))
        (asserts! (is-eq tx-sender CONTRACT_OWNER) ERR_UNAUTHORIZED)
        (map-set oracle-reputation
            { oracle-address: oracle-addr }
            (merge current-rep { is-active: false })
        )
        (ok true)
    )
)

;; read only functions
;;

;; Get oracle reputation details
(define-read-only (get-oracle-reputation (oracle-addr principal))
    (map-get? oracle-reputation { oracle-address: oracle-addr })
)

;; Get oracle registration details
(define-read-only (get-oracle-details (oracle-addr principal))
    (map-get? oracle-details { oracle-address: oracle-addr })
)

;; Get oracle feedback from a specific provider
(define-read-only (get-oracle-feedback (oracle-addr principal) (feedback-provider principal))
    (map-get? oracle-feedback { oracle-address: oracle-addr, feedback-provider: feedback-provider })
)

;; Check if oracle is active and in good standing
(define-read-only (is-oracle-trusted (oracle-addr principal))
    (match (map-get? oracle-reputation { oracle-address: oracle-addr })
        rep-data (and
                   (get is-active rep-data)
                   (>= (get reputation-score rep-data) u70)) ;; Threshold for trusted status
        false
    )
)

;; Get total number of registered oracles
(define-read-only (get-total-oracles)
    (var-get total-oracles)
)

;; Get oracle accuracy percentage
(define-read-only (get-oracle-accuracy (oracle-addr principal))
    (match (map-get? oracle-reputation { oracle-address: oracle-addr })
        rep-data (if (> (get total-submissions rep-data) u0)
                    (some (/ (* (get accurate-submissions rep-data) u100) (get total-submissions rep-data)))
                    (some u0))
        none
    )
)

;; private functions
;;

;; Calculate weighted reputation score based on submissions and feedback
(define-private (calculate-weighted-score (base-score uint) (feedback-count uint) (avg-feedback uint))
    (if (> feedback-count u0)
        (/ (+ (* base-score u70) (* avg-feedback u30)) u100) ;; 70% base score, 30% feedback
        base-score
    )
)
