;; BlockTix: NFT-Based Event Ticketing Smart Contract
;; A decentralized ticket management system that allows for:
;; - Event creation with configurable details and capacity
;; - Ticket purchases using STX
;; - Secondary market ticket transfers
;; - Event cancellation with refund capability

(define-non-fungible-token digital-ticket (string-ascii 100))

;; Contract Configuration
(define-constant system-owner tx-sender)
(define-constant ERR-OWNER-ONLY (err u100))
(define-constant ERR-TICKET-ALREADY-REGISTERED (err u101))
(define-constant ERR-TICKET-NOT-FOUND (err u102))
(define-constant ERR-NOT-TICKET-HOLDER (err u103))
(define-constant ERR-INPUT-VALIDATION-FAILED (err u104))
(define-constant ERR-EVENT-FULL (err u105))
(define-constant ERR-EVENT-ALREADY-CANCELLED (err u106))
(define-constant ERR-PAYMENT-FAILED (err u107))
(define-constant ERR-ACTIVE-TICKETS-EXIST (err u108))
(define-constant ERR-INVALID-RECIPIENT (err u109))
(define-constant ERR-EVENT-NOT-CANCELLED (err u110))

;; Input Validation Functions
(define-private (is-title-valid (event-title (string-ascii 100)))
  (and 
    (> (len event-title) u0) 
    (<= (len event-title) u100)
  )
)

(define-private (is-schedule-valid (event-schedule (string-ascii 50)))
  (and 
    (> (len event-schedule) u0) 
    (<= (len event-schedule) u50)
  )
)

(define-private (is-fee-valid (ticket-fee uint))
  (> ticket-fee u0)
)

(define-private (is-limit-valid (max-attendees uint))
  (> max-attendees u0)
)

;; Identity Validation
(define-private (is-recipient-valid (target-address principal))
  (not (is-eq target-address system-owner))
)

;; Data Storage
(define-map event-registry 
  {show-id: (string-ascii 100)} 
  {
    show-name: (string-ascii 100),
    show-schedule: (string-ascii 50),
    ticket-fee: uint,
    max-attendees: uint,
    registered-count: uint,
    is-cancelled: bool
  }
)

;; Attendee Registry
(define-map attendee-listing
  {show-id: (string-ascii 100), patron-address: principal} 
  bool
)

;; Public Query Functions
(define-read-only (get-ticket-owner (show-id (string-ascii 100)))
  (nft-get-owner? digital-ticket show-id)
)

(define-read-only (get-show-details (show-id (string-ascii 100)))
  (map-get? event-registry {show-id: show-id})
)

;; Create New Event
(define-public (create-show 
  (show-id (string-ascii 100))
  (show-name (string-ascii 100))
  (show-schedule (string-ascii 50))
  (ticket-fee uint)
  (max-attendees uint)
)
  (begin
    ;; Validate inputs
    (asserts! (is-title-valid show-name) ERR-INPUT-VALIDATION-FAILED)
    (asserts! (is-schedule-valid show-schedule) ERR-INPUT-VALIDATION-FAILED)
    (asserts! (is-fee-valid ticket-fee) ERR-INPUT-VALIDATION-FAILED)
    (asserts! (is-limit-valid max-attendees) ERR-INPUT-VALIDATION-FAILED)
    
    ;; Ensure event hasn't been created before
    (asserts! (is-none (get-show-details show-id)) ERR-TICKET-ALREADY-REGISTERED)
    
    ;; Initialize event data
    (map-set event-registry 
      {show-id: show-id}
      {
        show-name: show-name,
        show-schedule: show-schedule,
        ticket-fee: ticket-fee,
        max-attendees: max-attendees,
        registered-count: u0,
        is-cancelled: false
      }
    )
    
    ;; Register event in the system
    (nft-mint? digital-ticket show-id system-owner)
  )
)

;; Modify Event Details
(define-public (update-show
  (show-id (string-ascii 100))
  (new-name (string-ascii 100))
  (new-schedule (string-ascii 50))
  (new-price uint)
)
  (let ((show-data (unwrap! (get-show-details show-id) ERR-TICKET-NOT-FOUND)))
    (begin
      ;; Security check
      (asserts! (is-eq tx-sender system-owner) ERR-OWNER-ONLY)
      
      ;; Prevent updates after tickets sold
      (asserts! (is-eq (get registered-count show-data) u0) ERR-ACTIVE-TICKETS-EXIST)
      
      ;; Validate new parameters
      (asserts! (is-title-valid new-name) ERR-INPUT-VALIDATION-FAILED)
      (asserts! (is-schedule-valid new-schedule) ERR-INPUT-VALIDATION-FAILED)
      (asserts! (is-fee-valid new-price) ERR-INPUT-VALIDATION-FAILED)
      
      ;; Update event information
      (map-set event-registry 
        {show-id: show-id}
        (merge show-data {
          show-name: new-name,
          show-schedule: new-schedule,
          ticket-fee: new-price
        })
      )
      
      (ok true)
    )
  )
)

;; Purchase Event Ticket
(define-public (purchase-ticket (show-id (string-ascii 100)))
  (let ((show-data (unwrap! (get-show-details show-id) ERR-TICKET-NOT-FOUND)))
    (begin
      ;; Check event status
      (asserts! (not (get is-cancelled show-data)) ERR-EVENT-ALREADY-CANCELLED)
      
      ;; Check seat availability
      (asserts! 
        (< (get registered-count show-data) (get max-attendees show-data)) 
        ERR-EVENT-FULL
      )
      
      ;; Process payment
      (try! (stx-transfer? (get ticket-fee show-data) tx-sender system-owner))
      
      ;; Update ticket sales counter
      (map-set event-registry 
        {show-id: show-id}
        (merge show-data {registered-count: (+ (get registered-count show-data) u1)})
      )
      
      ;; Register attendee
      (map-set attendee-listing
        {show-id: show-id, patron-address: tx-sender} 
        true
      )
      
      ;; Mint ticket to buyer
      (nft-mint? digital-ticket show-id tx-sender)
    )
  )
)

;; Transfer Ticket to Another Attendee
(define-public (reassign-ticket 
  (show-id (string-ascii 100)) 
  (new-patron principal)
)
  (begin
    ;; Validate recipient
    (asserts! (is-recipient-valid new-patron) ERR-INVALID-RECIPIENT)
    
    ;; Verify ownership
    (asserts! 
      (is-eq tx-sender (unwrap! (nft-get-owner? digital-ticket show-id) ERR-TICKET-NOT-FOUND)) 
      ERR-NOT-TICKET-HOLDER
    )
    
    ;; Update attendee records
    (map-delete attendee-listing {show-id: show-id, patron-address: tx-sender})
    (map-set attendee-listing
      {show-id: show-id, patron-address: new-patron} 
      true
    )
    
    ;; Transfer NFT ticket
    (nft-transfer? digital-ticket show-id tx-sender new-patron)
  )
)

;; Cancel Event
(define-public (cancel-show (show-id (string-ascii 100)))
  (let ((show-data (unwrap! (get-show-details show-id) ERR-TICKET-NOT-FOUND)))
    (begin
      ;; Admin-only operation
      (asserts! (is-eq tx-sender system-owner) ERR-OWNER-ONLY)
      
      ;; Prevent duplicate cancellation
      (asserts! (not (get is-cancelled show-data)) ERR-EVENT-ALREADY-CANCELLED)
      
      ;; Mark event as cancelled
      (map-set event-registry
        {show-id: show-id}
        (merge show-data {is-cancelled: true})
      )
      
      (ok true)
    )
  )
)

;; Request Refund for Cancelled Event
(define-public (claim-refund (show-id (string-ascii 100)))
  (let (
    (show-data (unwrap! (get-show-details show-id) ERR-TICKET-NOT-FOUND))
    (patron (unwrap! (nft-get-owner? digital-ticket show-id) ERR-TICKET-NOT-FOUND))
  )
    (begin
      ;; Verify event is cancelled
      (asserts! (get is-cancelled show-data) ERR-EVENT-NOT-CANCELLED)
      
      ;; Verify ticket ownership
      (asserts! (is-eq tx-sender patron) ERR-NOT-TICKET-HOLDER)
      
      ;; Invalidate ticket
      (try! (nft-burn? digital-ticket show-id tx-sender))
      
      ;; Process refund
      (try! (stx-transfer? (get ticket-fee show-data) system-owner tx-sender))
      
      ;; Remove from attendee list
      (map-delete attendee-listing
        {show-id: show-id, patron-address: tx-sender}
      )
      
      (ok true)
    )
  )
)