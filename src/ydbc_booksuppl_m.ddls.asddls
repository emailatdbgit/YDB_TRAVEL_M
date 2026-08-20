@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'Booking Supp Projection View Manged'
@Metadata.ignorePropagatedAnnotations: false
@Metadata.allowExtensions: true
define view entity YDBC_BOOKSUPPL_M as projection on YDBI_BOOKSUPPL_M
{
     key TravelId,
  key BookingId,
  key BookingSupplementId,
      @ObjectModel.text.element: [ 'SupplemenDesc' ]
      SupplementId,
      _SupplementText.Description as SupplemenDesc : localized,
      Price,
      CurrencyCode,
      LastChangedAt,
      /* Associations */
      _Travel  : redirected to YDBC_TRAVEL_M,
      _Booking : redirected to parent YDBC_BOOKING_M,
      _Supplement,
      _SupplementText
}
