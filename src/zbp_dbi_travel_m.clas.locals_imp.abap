CLASS lhc_YDBI_TRAVEL_M DEFINITION INHERITING FROM cl_abap_behavior_handler.
  PRIVATE SECTION.

    METHODS get_instance_features FOR INSTANCE FEATURES
      keys REQUEST requested_features FOR ydbi_travel_m RESULT result.

    METHODS get_instance_authorizations FOR INSTANCE AUTHORIZATION
      keys REQUEST requested_authorizations FOR ydbi_travel_m RESULT result.

    METHODS earlynumbering_create FOR NUMBERING
       entities FOR CREATE ydbi_travel_m.

    METHODS earlynumbering_cba_Booking FOR NUMBERING
       entities FOR CREATE ydbi_travel_m\_Booking.

    METHODS acceptTravel FOR MODIFY
       keys FOR ACTION ydbi_travel_m~acceptTravel RESULT result.

    METHODS copyTravel FOR MODIFY
       keys FOR ACTION ydbi_travel_m~copyTravel.

    METHODS recalcTotPrice FOR MODIFY
       keys FOR ACTION ydbi_travel_m~recalcTotPrice.

    METHODS rejectTravel FOR MODIFY
       keys FOR ACTION ydbi_travel_m~rejectTravel RESULT result.

    METHODS calculateTotalPrice FOR DETERMINE ON MODIFY
       keys FOR ydbi_travel_m~calculateTotalPrice.

    METHODS validateBookingFee FOR VALIDATE ON SAVE
       keys FOR ydbi_travel_m~validateBookingFee.

    METHODS validateCurrencyCode FOR VALIDATE ON SAVE
       keys FOR ydbi_travel_m~validateCurrencyCode.

    METHODS validateCustomer FOR VALIDATE ON SAVE
       keys FOR ydbi_travel_m~validateCustomer.

    METHODS validateDates FOR VALIDATE ON SAVE
       keys FOR ydbi_travel_m~validateDates.

    METHODS validateStatus FOR VALIDATE ON SAVE
       keys FOR ydbi_travel_m~validateStatus.

ENDCLASS.

CLASS lhc_YDBI_TRAVEL_M IMPLEMENTATION.

  METHOD get_instance_features.
   READ ENTITIES OF ydbi_travel_m IN LOCAL MODE
   ENTITY ydbi_travel_m
   FIELDS ( TravelId OverallStatus )
   WITH CORRESPONDING #( keys )
   RESULT DATA(lt_travel).

  result  = VALUE #( FOR ls_travel IN lt_travel
                      (  %tky = ls_travel-%tky
                         %features-%action-acceptTravel = COND #( WHEN ls_travel-OverallStatus = 'A'
                                                                  THEN if_abap_behv=>fc-o-disabled
                                                                  ELSE if_abap_behv=>fc-o-enabled )
                         %features-%action-rejectTravel = COND #( WHEN ls_travel-OverallStatus = 'X'
                                                                  THEN if_abap_behv=>fc-o-disabled
                                                                  ELSE if_abap_behv=>fc-o-enabled )
                         %features-%assoc-_Booking  = COND #( WHEN ls_travel-OverallStatus = 'X'
                                                                  THEN if_abap_behv=>fc-o-disabled
                                                                  ELSE if_abap_behv=>fc-o-enabled )
                                                                   )
                 ).
  ENDMETHOD.

  METHOD get_instance_authorizations.
  ENDMETHOD.

  METHOD earlynumbering_create.
  DATA(lt_entities) = entities.

  DELETE lt_entities WHERE TravelId IS NOT INITIAL.
  TRY.
      cl_numberrange_runtime=>number_get(
        EXPORTING
          nr_range_nr       = '01'
          object            = '/DMO/TRV_M'
          quantity          = CONV #( lines( lt_entities ) )
        IMPORTING
          number            =  DATA(lv_latest_num)
          returncode        =  DATA(lv_code)
          returned_quantity =  DATA(lv_qty)
      ).
    CATCH cx_nr_object_not_found.
    CATCH cx_number_ranges INTO DATA(lo_error).

      LOOP AT lt_entities  INTO DATA(ls_entities).
        APPEND VALUE #( %cid =  ls_entities-%cid
                        %key = ls_entities-%key  )
               TO failed-ydbi_travel_m.
        APPEND VALUE #( %cid =  ls_entities-%cid
                        %key = ls_entities-%key
                        %msg =  lo_error )
               TO reported-ydbi_travel_m.

      ENDLOOP.
      EXIT.
  ENDTRY.
  ASSERT lv_qty = lines( lt_entities ).
*    DATA: lt_travel_tech_m TYPE TABLE FOR MAPPED EARLY ydbi_travel_m,
*          ls_travel_tech_m LIKE LINE OF lt_travel_tech_m.
  DATA(lv_curr_num)   =  lv_latest_num - lv_qty.

  LOOP AT lt_entities  INTO ls_entities.

    lv_curr_num = lv_curr_num + 1.
*      ls_travel_tech_m = VALUE #( %cid =  ls_entities-%cid
*                                  TravelId = lv_curr_num
*       ) .
*      APPEND ls_travel_tech_m TO mapped-yi_travel_tech_m.

    APPEND VALUE #( %cid =  ls_entities-%cid
                    TravelId = lv_curr_num  )
             TO mapped-ydbi_travel_m.
  ENDLOOP.
  ENDMETHOD.

  METHOD earlynumbering_cba_Booking.
  DATA : lv_max_booking TYPE /dmo/booking_id.

  READ ENTITIES OF yDBi_travel_m IN LOCAL MODE
   ENTITY ydbi_travel_m BY \_Booking
   FROM CORRESPONDING #( entities )
   LINK DATA(lt_link_data).

  LOOP AT entities ASSIGNING FIELD-SYMBOL(<ls_group_entity>)
                             GROUP BY <ls_group_entity>-TravelId .


    lv_max_booking = REDUCE #( INIT lv_max = CONV /dmo/booking_id( '0' )
                               FOR ls_link IN lt_link_data USING KEY entity
                                    WHERE ( source-TravelId = <ls_group_entity>-TravelId  )
                               NEXT  lv_max = COND  /dmo/booking_id( WHEN lv_max < ls_link-target-BookingId
                                                                     THEN ls_link-target-BookingId
                                                                      ELSE lv_max ) ).
    lv_max_booking  = REDUCE #( INIT lv_max = lv_max_booking
                                 FOR ls_entity IN entities USING KEY entity
                                     WHERE ( TravelId = <ls_group_entity>-TravelId  )
                                   FOR ls_booking IN ls_entity-%target
                                   NEXT lv_max = COND  /dmo/booking_id( WHEN lv_max < ls_booking-BookingId
                                                                      THEN ls_booking-BookingId
                                                                       ELSE lv_max )
     ).

    LOOP AT entities ASSIGNING FIELD-SYMBOL(<ls_entities>)
                      USING KEY entity
                       WHERE TravelId = <ls_group_entity>-TravelId.

      LOOP AT <ls_entities>-%target ASSIGNING FIELD-SYMBOL(<ls_booking>).
        APPEND CORRESPONDING #( <ls_booking> )  TO   mapped-ydbi_booking_m
           ASSIGNING FIELD-SYMBOL(<ls_new_map_book>).
        IF <ls_booking>-BookingId IS INITIAL.
          lv_max_booking += 10.


          <ls_new_map_book>-BookingId = lv_max_booking.
        ENDIF.

      ENDLOOP.



    ENDLOOP.

  ENDLOOP.

  ENDMETHOD.

  METHOD acceptTravel.
  MODIFY ENTITIES OF ydbi_travel_m IN LOCAL MODE
  ENTITY ydbi_travel_m
   UPDATE FIELDS ( OverallStatus )
   WITH VALUE #( FOR ls_keys IN keys ( %tky = ls_keys-%tky
                                       OverallStatus = 'A' ) ).

  READ ENTITIES OF ydbi_travel_m IN LOCAL MODE
  ENTITY ydbi_travel_m
  ALL FIELDS WITH CORRESPONDING #( keys )
  RESULT DATA(lt_result).
  .

  result  = VALUE #( FOR ls_result IN lt_result ( %tky = ls_result-%tky
                                               %param  =  ls_result ) ).
  ENDMETHOD.

  METHOD copyTravel.
  DATA: it_travel        TYPE TABLE FOR CREATE ydbi_travel_m,
        it_booking_cba   TYPE TABLE FOR CREATE ydbi_travel_m\_Booking,
        it_booksuppl_cba TYPE TABLE FOR CREATE ydbi_booking_m\_Bookingsuppl.


  READ TABLE keys ASSIGNING FIELD-SYMBOL(<ls_without_cid>) WITH KEY %cid = ' '.
  ASSERT <ls_without_cid> IS NOT ASSIGNED.

  READ ENTITIES OF ydbi_travel_m IN LOCAL MODE
    ENTITY ydbi_travel_m
    ALL FIELDS WITH CORRESPONDING #( keys )
    RESULT DATA(lt_travel_r)
    FAILED DATA(lt_failed).

  READ ENTITIES OF ydbi_travel_m IN LOCAL MODE
    ENTITY ydbi_travel_m BY \_Booking
    ALL FIELDS WITH CORRESPONDING #( lt_travel_r )
    RESULT DATA(lt_booking_r).

  READ ENTITIES OF ydbi_travel_m IN LOCAL MODE
    ENTITY ydbi_booking_m BY \_Bookingsuppl
    ALL FIELDS WITH CORRESPONDING #( lt_booking_r )
    RESULT DATA(lt_booksupp_r).

  LOOP AT lt_travel_r ASSIGNING FIELD-SYMBOL(<ls_travel_r>).
    APPEND VALUE #( %cid =  keys[ KEY entity  TravelId = <ls_travel_r>-TravelId ]-%cid
                    %data = CORRESPONDING #( <ls_travel_r> EXCEPT TravelId ) )
             TO it_travel ASSIGNING FIELD-SYMBOL(<ls_travel>).
    <ls_travel>-BeginDate = cl_abap_context_info=>get_system_date( ).
    <ls_travel>-EndDate = cl_abap_context_info=>get_system_date( ) + 30.
    <ls_travel>-OverallStatus = 'O'.

    APPEND VALUE #( %cid_ref = <ls_travel>-%cid )
       TO it_booking_cba ASSIGNING FIELD-SYMBOL(<it_booking>).

    LOOP AT lt_booking_r ASSIGNING FIELD-SYMBOL(<ls_booking_r>)
                         USING KEY entity
                         WHERE TravelId = <ls_travel_r>-TravelId.
      APPEND VALUE #( %cid = <ls_travel>-%cid && <ls_booking_r>-BookingId
                    %data = CORRESPONDING #( <ls_booking_r> EXCEPT TravelId ) )
             TO  <it_booking>-%target ASSIGNING FIELD-SYMBOL(<ls_booking_n>).
      <ls_booking_n>-BookingStatus  = 'N'.
      APPEND VALUE #( %cid_ref = <ls_booking_n>-%cid )
           TO it_booksuppl_cba ASSIGNING FIELD-SYMBOL(<ls_booksupp>).
      LOOP AT lt_booksupp_r ASSIGNING FIELD-SYMBOL(<ls_booksupp_r>)
                            USING KEY entity
                            WHERE TravelId = <ls_travel_r>-TravelId
                            AND   BookingId = <ls_booking_r>-BookingId.

        APPEND VALUE #( %cid = <ls_travel>-%cid && <ls_booking_r>-BookingId && <ls_booksupp_r>-BookingSupplementId
                        %data = CORRESPONDING #( <ls_booksupp_r> EXCEPT TravelId BookingId ) )
                TO <ls_booksupp>-%target.

      ENDLOOP.

    ENDLOOP.
  ENDLOOP.
* ☺

  MODIFY ENTITIES OF ydbi_travel_m IN LOCAL MODE
    ENTITY ydbi_travel_m
    CREATE FIELDS ( AgencyId CustomerId BeginDate EndDate BookingFee TotalPrice CurrencyCode OverallStatus Description )
    WITH it_travel
    ENTITY ydbi_travel_m
     CREATE BY \_Booking
     FIELDS ( BookingId BookingDate CustomerId CarrierId ConnectionId FlightDate FlightPrice CurrencyCode BookingStatus )
     WITH it_booking_cba
    ENTITY ydbi_booking_m
     CREATE BY \_Bookingsuppl
     FIELDS ( BookingSupplementId SupplementId Price CurrencyCode )
     WITH it_booksuppl_cba
     MAPPED DATA(it_mapped).


  mapped-ydbi_travel_m = it_mapped-ydbi_travel_m.
  ENDMETHOD.

  METHOD recalcTotPrice.
  TYPES : BEGIN OF ty_total,
            price TYPE /dmo/total_price,
            curr  TYPE /dmo/currency_code,
          END OF ty_total .
  DATA: lt_total      TYPE TABLE OF ty_total,
        lv_conv_price TYPE ty_total-price.
*☺

  READ ENTITIES OF ydbi_travel_m IN LOCAL MODE
   ENTITY ydbi_travel_m
   FIELDS ( BookingFee CurrencyCode )
   WITH CORRESPONDING #( keys )
   RESULT DATA(lt_travel).

  DELETE lt_travel WHERE CurrencyCode IS INITIAL.

  READ ENTITIES OF ydbi_travel_m IN LOCAL MODE
   ENTITY ydbi_travel_m BY \_Booking
   FIELDS ( FlightPrice CurrencyCode )
   WITH CORRESPONDING #( lt_travel )
   RESULT DATA(lt_ba_booking).

  READ ENTITIES OF ydbi_travel_m IN LOCAL MODE
   ENTITY ydbi_booking_m BY \_Bookingsuppl
   FIELDS ( Price CurrencyCode )
   WITH CORRESPONDING #( lt_ba_booking )
   RESULT DATA(lt_ba_booksuppl).

  LOOP AT lt_travel ASSIGNING FIELD-SYMBOL(<ls_travel>).

    lt_total =  VALUE #( ( price = <ls_travel>-BookingFee curr = <ls_travel>-CurrencyCode ) ).

    LOOP AT lt_ba_booking ASSIGNING FIELD-SYMBOL(<ls_booking>)
                               USING KEY entity
                                WHERE TravelId = <ls_travel>-TravelId
                                AND CurrencyCode IS NOT INITIAL.

      APPEND VALUE #( price = <ls_booking>-FlightPrice curr = <ls_booking>-CurrencyCode )
         TO lt_total.

      LOOP AT lt_ba_booksuppl ASSIGNING FIELD-SYMBOL(<ls_booksuppl>)
                                        USING KEY entity
                                        WHERE TravelId = <ls_booking>-TravelId
                                         AND  BookingId = <ls_booking>-BookingId
                                          AND CurrencyCode IS NOT INITIAL..
        APPEND VALUE #( price = <ls_booksuppl>-Price curr = <ls_booksuppl>-CurrencyCode )
         TO lt_total.
      ENDLOOP.
    ENDLOOP.

    LOOP AT lt_total ASSIGNING FIELD-SYMBOL(<ls_total>).

      IF <ls_total>-curr = <ls_travel>-CurrencyCode.
        lv_conv_price = <ls_total>-price.
      ELSE.

        /dmo/cl_flight_amdp=>convert_currency(
          EXPORTING
            iv_amount               = <ls_total>-price
            iv_currency_code_source = <ls_total>-curr
            iv_currency_code_target = <ls_travel>-CurrencyCode
            iv_exchange_rate_date   =  cl_abap_context_info=>get_system_date( )
          IMPORTING
            ev_amount               = lv_conv_price
        ).

      ENDIF.

      <ls_travel>-TotalPrice =  <ls_travel>-TotalPrice + lv_conv_price.
    ENDLOOP.


  ENDLOOP.

  MODIFY ENTITIES OF ydbi_travel_m IN LOCAL MODE
  ENTITY ydbi_travel_m
  UPDATE FIELDS ( TotalPrice )
  WITH CORRESPONDING #( lt_travel ).
  ENDMETHOD.

  METHOD rejectTravel.
  MODIFY ENTITIES OF ydbi_travel_m IN LOCAL MODE
 ENTITY ydbi_travel_m
  UPDATE FIELDS ( OverallStatus )
  WITH VALUE #( FOR ls_keys IN keys ( %tky = ls_keys-%tky
                                      OverallStatus = 'X' ) ).

  READ ENTITIES OF ydbi_travel_m IN LOCAL MODE
  ENTITY ydbi_travel_m
  ALL FIELDS WITH CORRESPONDING #( keys )
  RESULT DATA(lt_result).
  .

  result  = VALUE #( FOR ls_result IN lt_result ( %tky = ls_result-%tky
                                               %param  =  ls_result ) ).
  ENDMETHOD.

  METHOD calculateTotalPrice.
  MODIFY ENTITIES OF ydbi_travel_m IN LOCAL MODE
    ENTITY ydbi_travel_m
    EXECUTE recalcTotPrice
    FROM CORRESPONDING #( keys ).
  ENDMETHOD.

  METHOD validateBookingFee.
  ENDMETHOD.

  METHOD validateCurrencyCode.
  ENDMETHOD.

  METHOD validateCustomer.
  READ ENTITY  IN LOCAL MODE ydbi_travel_m
   FIELDS ( CustomerId )
   WITH CORRESPONDING #( keys )
   RESULT DATA(lt_travel).

  DATA: lt_cust TYPE SORTED TABLE OF /dmo/customer WITH UNIQUE KEY customer_id.

  lt_cust = CORRESPONDING #( lt_travel DISCARDING DUPLICATES MAPPING customer_id = CustomerId  ).
  DELETE lt_cust WHERE customer_id IS INITIAL.
  SELECT
   FROM /dmo/customer
   FIELDS customer_id
   FOR ALL ENTRIES IN @lt_cust
   WHERE customer_id = @lt_cust-customer_id
   INTO TABLE @DATA(lt_cust_db).
    IF sy-subrc IS INITIAL.

    ENDIF.

    LOOP AT lt_travel ASSIGNING FIELD-SYMBOL(<ls_travel>).

      IF <ls_travel>-CustomerId IS INITIAL
         OR  NOT line_exists( lt_cust_db[ customer_id = <ls_travel>-CustomerId  ] )   .

        APPEND VALUE #( %tky = <ls_travel>-%tky )
                   TO failed-ydbi_travel_m.
        APPEND VALUE #( %tky = <ls_travel>-%tky
                        %msg = NEW /dmo/cm_flight_messages(
                                            textid                = /dmo/cm_flight_messages=>customer_unkown
                                           customer_id           = <ls_travel>-CustomerId
                                severity              = if_abap_behv_message=>severity-error
                                )
                        %element-CustomerId = if_abap_behv=>mk-on

        )
                   TO reported-ydbi_travel_m.



      ENDIF.

    ENDLOOP.

  ENDMETHOD.

  METHOD validateDates.
   READ ENTITIES OF ydbi_travel_m IN LOCAL MODE
              ENTITY ydbi_travel_m
                FIELDS ( BeginDate EndDate )
                WITH CORRESPONDING #( keys )
              RESULT DATA(lt_travels).

    LOOP AT lt_travels INTO DATA(travel).

      IF travel-EndDate < travel-BeginDate.  "end_date before begin_date

        APPEND VALUE #( %tky = travel-%tky ) TO failed-ydbi_travel_m.

        APPEND VALUE #( %tky = travel-%tky
                        %msg = NEW /dmo/cm_flight_messages(
                                   textid     = /dmo/cm_flight_messages=>begin_date_bef_end_date
                                   severity   = if_abap_behv_message=>severity-error
                                   begin_date = travel-BeginDate
                                   end_date   = travel-EndDate
                                   travel_id  = travel-TravelId )
                        %element-BeginDate   = if_abap_behv=>mk-on
                        %element-EndDate     = if_abap_behv=>mk-on
                     ) TO reported-ydbi_travel_m.

      ELSEIF travel-BeginDate < cl_abap_context_info=>get_system_date( ).  "begin_date must be in the future

        APPEND VALUE #( %tky        = travel-%tky ) TO failed-ydbi_travel_m.

        APPEND VALUE #( %tky = travel-%tky
                        %msg = NEW /dmo/cm_flight_messages(
                                    textid   = /dmo/cm_flight_messages=>begin_date_on_or_bef_sysdate
                                    severity = if_abap_behv_message=>severity-error )
                        %element-BeginDate  = if_abap_behv=>mk-on
                        %element-EndDate    = if_abap_behv=>mk-on
                      ) TO reported-ydbi_travel_m.
      ENDIF.

    ENDLOOP.
  ENDMETHOD.

  METHOD validateStatus.
*    READ ENTITIES OF ydbi_travel_m IN LOCAL MODE
*        ENTITY ydbi_travel_m
*          FIELDS ( OverallStatus )
*          WITH CORRESPONDING #( keys )
*        RESULT DATA(lt_travels).
*
*    LOOP AT lt_travels INTO DATA(ls_travel).
*      CASE ls_travel-OverallStatus.
*        WHEN 'O'.  " Open
*        WHEN 'X'.  " Cancelled
*        WHEN 'A'.  " Accepted
*
*        WHEN OTHERS.
*          APPEND VALUE #( %tky = ls_travel-%tky ) TO failed-ydbi_travel_m.
*
*          APPEND VALUE #( %tky = ls_travel-%tky
*                          %msg = NEW /dmo/cm_flight_messages(
*                                     textid = /dmo/cm_flight_messages=>status_invalid
*                                     severity = if_abap_behv_message=>severity-error
*                                     status = ls_travel-OverallStatus )
*                          %element-OverallStatus = if_abap_behv=>mk-on
*                        ) TO reported-ydbi_travel_m.
*      ENDCASE.
*    ENDLOOP.
  ENDMETHOD.

ENDCLASS.

CLASS lsc_YDBI_TRAVEL_M DEFINITION INHERITING FROM cl_abap_behavior_saver.
  PROTECTED SECTION.

    METHODS save_modified REDEFINITION.

    METHODS cleanup_finalize REDEFINITION.

ENDCLASS.

CLASS lsc_YDBI_TRAVEL_M IMPLEMENTATION.

  METHOD save_modified.


**********************************************************************
**********************************************************************

    DATA: lt_book_suppl TYPE STANDARD TABLE OF ybooksupp_tech_m.
    IF create-ydbi_booksuppl_m IS NOT INITIAL.

      lt_book_suppl = VALUE #( FOR ls_booksup IN  create-ydbi_booksuppl_m (
                                           travel_id  = ls_booksup-TravelId
                                           booking_id = ls_booksup-BookingId
                                           booking_supplement_id  = ls_booksup-BookingSupplementId
                                           supplement_id   = ls_booksup-SupplementId
                                           price   = ls_booksup-Price
                                           currency_code    = ls_booksup-CurrencyCode
                                           last_changed_at = ls_booksup-LastChangedAt
                                             )  ).

      INSERT ydb_booksupp_m FROM TABLE @lt_book_suppl.

    endif.
      IF update-ydbi_booksuppl_m IS NOT INITIAL.

        lt_book_suppl = VALUE #( FOR ls_booksup IN  update-ydbi_booksuppl_m (
                                          travel_id  = ls_booksup-TravelId
                                          booking_id = ls_booksup-BookingId
                                          booking_supplement_id  = ls_booksup-BookingSupplementId
                                          supplement_id   = ls_booksup-SupplementId
                                          price   = ls_booksup-Price
                                          currency_code    = ls_booksup-CurrencyCode
                                          last_changed_at = ls_booksup-LastChangedAt
                                            )  ).


        UPDATE ydb_booksupp_m FROM TABLE @lt_book_suppl.

      ENDIF.
      IF delete-ydbi_booksuppl_m IS NOT INITIAL.

        lt_book_suppl = VALUE #( FOR ls_del IN  delete-ydbi_booksuppl_m (
                                           travel_id  = ls_del-TravelId
                                           booking_id = ls_del-BookingId
                                           booking_supplement_id  = ls_del-BookingSupplementId
                                             )  ).


        DELETE ydb_booksupp_m FROM TABLE @lt_book_suppl.

      ENDIF.

  ENDMETHOD.

  METHOD cleanup_finalize.
  ENDMETHOD.

ENDCLASS.
