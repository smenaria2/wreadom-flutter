# Author UPI support: text for the website Privacy Policy and Terms

The app loads its Privacy Policy and Terms from wreadom.in (see
`legal_document_service.dart`), so these clauses must be added to the website
pages. Have them reviewed before publishing; this is not legal advice.

## Privacy Policy: add a section "Author support (UPI)"

> **Author support (UPI).** Authors may choose to add their UPI ID to their
> Wreadom profile so readers can support them. An author's UPI ID is visible to
> signed-in users who view that author's profile. If you tell us that you have
> supported an author, we store your display name, profile photo, the author's
> ID, the optional amount and the optional UPI reference number you provide, and
> the time. Your name and photo may be shown in that author's supporters list,
> and the author can see your reference number. You can delete your entry at any
> time. Payments are made directly between you and the author through your own
> UPI app. Wreadom does not process, receive or store payments, and does not
> collect your bank account, card or UPI PIN details.

## Terms of Service: add a section "Author support (tips)"

> **Author support (tips).** Support is voluntary and goes 100% to the author
> through UPI. Wreadom is not a party to these payments, does not charge a fee,
> and does not hold, verify or guarantee them. Supporting an author does not
> unlock any content or feature. Refunds and disputes are between you and the
> author and your payment provider. Authors are responsible for the accuracy of
> their UPI ID and for any taxes or legal obligations on money they receive. A
> "confirmed" tick means only that the author marked the payment as received.
> Do not add someone else's UPI ID, misuse the supporters list, or claim
> payments you have not made; we may remove such entries or restrict accounts.

## Play Console Data safety

- Declare **User-generated / Other info** (UPI ID, supporter name) as collected,
  purpose "App functionality", not shared.
- Financial info → "User payment info": **do not** declare. The app never
  collects card/bank details, and the UPI ID is a public payee address entered
  by the author.
- "Purchases" → none; no digital goods are sold through this feature.
- Keep the in-app wording "tip / support" (not "donation") and keep supporter
  recognition cosmetic only.
