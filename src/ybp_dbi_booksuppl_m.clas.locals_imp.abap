CLASS lhc_yDBI_BOOKSUPPL_M DEFINITION INHERITING FROM cl_abap_behavior_handler.
  PRIVATE SECTION.

    METHODS calculateTotalPrice FOR DETERMINE ON MODIFY
       keys FOR yDBI_BOOKSUPPL_M~calculateTotalPrice.

    METHODS validateCurrencyCode FOR VALIDATE ON SAVE
       keys FOR yDBI_BOOKSUPPL_M~validateCurrencyCode.

    METHODS validatePrice FOR VALIDATE ON SAVE
       keys FOR yDBI_BOOKSUPPL_M~validatePrice.

    METHODS validateSupplement FOR VALIDATE ON SAVE
       keys FOR yDBI_BOOKSUPPL_M~validateSupplement.

ENDCLASS.

CLASS lhc_yDBI_BOOKSUPPL_M IMPLEMENTATION.

  METHOD calculateTotalPrice.
  DATA: it_travel TYPE STANDARD TABLE OF ydbi_travel_m WITH UNIQUE HASHED KEY key COMPONENTS TravelId.

    it_travel =  CORRESPONDING #(  keys DISCARDING DUPLICATES MAPPING TravelId = TravelId ).
    MODIFY ENTITIES OF ydbi_travel_m IN LOCAL MODE
     ENTITY ydbi_travel_m
     EXECUTE recalcTotPrice
     FROM CORRESPONDING #( it_travel ).
  ENDMETHOD.

  METHOD validateCurrencyCode.
  ENDMETHOD.

  METHOD validatePrice.
  ENDMETHOD.

  METHOD validateSupplement.
  ENDMETHOD.

ENDCLASS.
