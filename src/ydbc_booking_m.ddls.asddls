@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'Booking Projetion'
@Metadata.ignorePropagatedAnnotations: false
@Metadata.allowExtensions: true
define view entity YDBC_BOOKING_M as projection on YDBI_BOOKING_M
{
    key TravelId,
  key BookingId,
      BookingDate,
      @ObjectModel.text.element: [ 'CustomerName' ]
      CustomerId,
      _Customer.LastName         as CustomerName,
      @ObjectModel.text.element: [ 'CarrierName' ]
      CarrierId,
      _Carrier.Name              as CarrierName,
      ConnectionId,
      FlightDate,
      FlightPrice,
      CurrencyCode,
      @ObjectModel.text.element: [ 'BookingStatusText' ]
      BookingStatus,
      _Booking_Status._Text.Text as BookingStatusText : localized,
      LastChangedAt,
      /* Associations */
      _Bookingsuppl : redirected to composition child YDBC_BOOKSUPPL_M,
      _Booking_Status,
      _Carrier,
      _Connection,
      _Customer,
      _Travel       : redirected to parent YDBC_TRAVEL_M
}
