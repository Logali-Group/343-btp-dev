class lhc_Travel definition inheriting from cl_abap_behavior_handler.
  private section.

    constants:
      begin of travel_status,
        open     type c length 1 value 'O', "Open
        accepted type c length 1 value 'A', "Accepted
        rejected type c length 1 value 'X', "Rejected
      end of travel_status.

    methods get_instance_features for instance features
      importing keys request requested_features for Travel result result.

    methods get_instance_authorizations for instance authorization
      importing keys request requested_authorizations for Travel result result.

    methods get_global_authorizations for global authorization
      importing request requested_authorizations for Travel result result.

    methods precheck_create for precheck
      importing entities for create Travel.

    methods precheck_update for precheck
      importing entities for update Travel.

    methods acceptTravel for modify
      importing keys for action Travel~acceptTravel result result.

    methods deductDiscount for modify
      importing keys for action Travel~deductDiscount result result.

    methods reCalcTotalPrice for modify
      importing keys for action Travel~reCalcTotalPrice.

    methods rejectTravel for modify
      importing keys for action Travel~rejectTravel result result.

    methods Resume for modify
      importing keys for action Travel~Resume.

    methods calculateTotalPrice for determine on modify
      importing keys for Travel~calculateTotalPrice.

    methods setStatusOpen for determine on modify
      importing keys for Travel~setStatusOpen.

    methods setTravelNumber for determine on save
      importing keys for Travel~setTravelNumber.

    methods validateAgency for validate on save
      importing keys for Travel~validateAgency.

    methods validateCurrencyCode for validate on save
      importing keys for Travel~validateCurrencyCode.

    methods validateCustomer for validate on save
      importing keys for Travel~validateCustomer.

    methods validateDates for validate on save
      importing keys for Travel~validateDates.

endclass.

class lhc_Travel implementation.

  method get_instance_features.
  endmethod.

  method get_instance_authorizations.
  endmethod.

  method get_global_authorizations.
  endmethod.

  method precheck_create.
  endmethod.

  method precheck_update.
  endmethod.

  method acceptTravel.

    modify entities of Z_r_TRAVEL_343 in local mode
           entity Travel
           update
           fields ( OverallStatus )
           with value #( for key in keys ( %tky          = key-%tky
                                           OverallStatus = travel_status-accepted )  ).

    read entities of Z_r_TRAVEL_343 in local mode
         entity Travel
         all fields
         with corresponding #( keys )
         result data(travels).

    result = value #( for travel in travels (  %tky   = travel-%tky
                                               %param = travel ) ).

  endmethod.

  method deductDiscount.

    data travels_for_update type table for update Z_r_TRAVEL_343.

    data(keys_with_valid_discount) = keys.

    loop at keys_with_valid_discount assigning field-symbol(<key_valid_discount>)
         where %param-discount_percent is initial
            or %param-discount_percent > 100
            or %param-discount_percent <= 0.

      append value #( %tky = <key_valid_discount>-%tky ) to failed-travel.

    endloop.

    "check failed-travel is initial.

    read entities of Z_r_TRAVEL_343 in local mode
           entity Travel
           fields ( BookingFee )
           with corresponding #( keys_with_valid_discount )
           result data(travels).

    data percentage type decfloat16.

    loop at travels assigning field-symbol(<travel>).

      data(discount_percent) = keys_with_valid_discount[ key id %tky = <travel>-%tky ]-%param-discount_percent.
      percentage = discount_percent / 100.
      data(reduce_fee) = <travel>-BookingFee * ( 1 - percentage ).

      append value #( %tky       = <travel>-%tky
                      BookingFee = reduce_fee ) to travels_for_update.

    endloop.

    modify entities of Z_r_TRAVEL_343 in local mode
           entity Travel
           update
           fields ( BookingFee )
           with travels_for_update.

    read entities of Z_r_TRAVEL_343 in local mode
             entity Travel
             all fields
             with corresponding #( keys )
             result data(travels_with_discount).

    result = value #( for travel in travels_with_discount (  %tky   = travel-%tky
                                                             %param = travel ) ).

  endmethod.

  method reCalcTotalPrice.
  endmethod.

  method rejectTravel.

    modify entities of Z_r_TRAVEL_343 in local mode
         entity Travel
         update
         fields ( OverallStatus )
         with value #( for key in keys ( %tky          = key-%tky
                                         OverallStatus = travel_status-rejected )  ).

    read entities of Z_r_TRAVEL_343 in local mode
         entity Travel
         all fields
         with corresponding #( keys )
         result data(travels).

    result = value #( for travel in travels (  %tky   = travel-%tky
                                               %param = travel ) ).


  endmethod.

  method Resume.
  endmethod.

  method calculateTotalPrice.
  endmethod.

  method setStatusOpen.

    read entities of Z_r_TRAVEL_343 in local mode
         entity Travel
         fields ( OverallStatus )
         with corresponding #( keys )
         result data(travels).

    delete travels where OverallStatus is not initial.

    check travels is not initial.

    modify entities of Z_r_TRAVEL_343 in local mode
       entity Travel
       update
       fields ( OverallStatus )
       with value #( for travel in travels index into i ( %tky          = travel-%tky
                                                          OverallStatus = travel_status-open )  ).



  endmethod.

  method setTravelNumber.


* EML - Entity Manipulation Language
    read entities of Z_r_TRAVEL_343 in local mode
           entity Travel
           fields ( TravelID )
           with corresponding #( keys )
           result data(travels).

    delete travels where TravelID is not initial.

    check travels is not initial.

    select single from ztravel_343
           fields max( travel_id )
           into @data(lv_max_travelid).

    modify entities of Z_r_TRAVEL_343 in local mode
       entity Travel
       update
       fields ( TravelID )
       with value #( for travel in travels index into i ( %tky     = travel-%tky
                                                          TravelID = lv_max_travelid + i )  ).

  endmethod.

  method validateAgency.
  endmethod.

  method validateCurrencyCode.
  endmethod.

  method validateCustomer.
  endmethod.

  method validateDates.
  endmethod.

endclass.
