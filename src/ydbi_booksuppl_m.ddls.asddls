@AbapCatalog.viewEnhancementCategory: [#NONE]
@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'Booking Supp Interface View Manged'
@Metadata.ignorePropagatedAnnotations: true
define view entity yDBI_BOOKSUPPL_M as select from ydb_booksupp_m
association        to parent YDBI_BOOKING_M as _Booking  on  $projection.TravelId  = _Booking.TravelId
                                            and $projection.BookingId = _Booking.BookingId
  association [1..1] to YDBI_TRAVEL_M         as _Travel on  $projection.TravelId = _Travel.TravelId
  association [1..1] to /DMO/I_Supplement        as _Supplement     on  $projection.SupplementId = _Supplement.SupplementID
  association [1..*] to /DMO/I_SupplementText    as _SupplementText on  $projection.SupplementId = _SupplementText.SupplementID


{
  key travel_id             as TravelId,
   key booking_id            as BookingId,
  key booking_supplement_id as BookingSupplementId,
      supplement_id         as SupplementId,
      @Semantics.amount.currencyCode: 'CurrencyCode'
      price                 as Price,
      currency_code         as CurrencyCode,
        //the persistent field last_changed_at plays a special role as a field ETag.
      @Semantics.systemDateTime.localInstanceLastChangedAt: true
      last_changed_at       as LastChangedAt,
      _Travel,
      _Booking,
      _Supplement,
      _SupplementText
}
