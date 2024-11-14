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

      append value #( %tky                     = <key_valid_discount>-%tky
                      %msg                       = new /dmo/cm_flight_messages(
                                                             textid   = /dmo/cm_flight_messages=>discount_invalid
                                                             severity = if_abap_behv_message=>severity-error )
                      %element-BookingFee        = if_abap_behv=>mk-on
                      %op-%action-deductDiscount = if_abap_behv=>mk-on ) to reported-travel.

    endloop.

    check failed-travel is initial.

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

     modify entities of Z_r_TRAVEL_343 in local mode
       entity Travel
       execute reCalcTotalPrice
       from corresponding #( keys ).

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

    data agencies type sorted table of /dmo/agency with unique key client agency_id.

    read entities of Z_r_TRAVEL_343 in local mode
         entity Travel
         fields ( AgencyID )
         with corresponding #( keys )
         result data(travels).

    agencies = corresponding #( travels discarding duplicates mapping agency_id = AgencyID except * ).
    delete agencies where agency_id is initial.

    if agencies is not initial.
      select from /dmo/agency as ddbb
             inner join @agencies as http_req on ddbb~agency_id eq http_req~agency_id
             fields ddbb~agency_id
             into table @data(valid_agencies).
    endif.

    loop at travels into data(travel).

      if travel-AgencyID is initial.

        append value #( %tky = travel-%tky ) to failed-travel.

        append value #( %tky                = travel-%tky
                        %state_area         = 'VALIDATE_AGENCY'
                        %msg                = new /dmo/cm_flight_messages(
                                                               textid   = /dmo/cm_flight_messages=>enter_agency_id
                                                               severity = if_abap_behv_message=>severity-error )
                        %element-AgencyID = if_abap_behv=>mk-on ) to reported-travel.

      elseif not line_exists( valid_agencies[ agency_id = travel-AgencyID ] ).

        append value #( %tky = travel-%tky ) to failed-travel.

        append value #( %tky                = travel-%tky
                        %state_area         = 'VALIDATE_AGENCY'
                        %msg                = new /dmo/cm_flight_messages(
                                                               textid      = /dmo/cm_flight_messages=>agency_unkown
                                                               agency_id   = travel-AgencyID
                                                               severity    = if_abap_behv_message=>severity-error )
                        %element-AgencyID = if_abap_behv=>mk-on ) to reported-travel.

      endif.


    endloop.


  endmethod.

  method validateCurrencyCode.
  endmethod.

  method validateCustomer.

*T1 C1
*T2 C2
*T3 C2
*T4 C4
*T5 C1
*
*C1
*C2
*C4 ?????
*
*C2
*C4

    data customers type sorted table of /dmo/customer with unique key client customer_id.

    read entities of Z_r_TRAVEL_343 in local mode
         entity Travel
         fields ( CustomerID )
         with corresponding #( keys )
         result data(travels).

    customers = corresponding #( travels discarding duplicates mapping customer_id = CustomerID except * ).

    if customers is not initial.
      select from /dmo/customer as ddbb
             inner join @customers as http_req on ddbb~customer_id eq http_req~customer_id
             fields ddbb~customer_id
             into table @data(valid_customers).
    endif.

    loop at travels into data(travel).

      if travel-CustomerID is initial.

        append value #( %tky = travel-%tky ) to failed-travel.

        append value #( %tky                = travel-%tky
                        %state_area         = 'VALIDATE_CUSTOMER'
                        %msg                = new /dmo/cm_flight_messages(
                                                               textid   = /dmo/cm_flight_messages=>enter_customer_id
                                                               severity = if_abap_behv_message=>severity-error )
                        %element-CustomerID = if_abap_behv=>mk-on ) to reported-travel.

      elseif travel-CustomerID is not initial and not line_exists( valid_customers[ customer_id = travel-CustomerID ] ).

        append value #( %tky = travel-%tky ) to failed-travel.

        append value #( %tky                = travel-%tky
                        %state_area         = 'VALIDATE_CUSTOMER'
                        %msg                = new /dmo/cm_flight_messages(
                                                               textid      = /dmo/cm_flight_messages=>customer_unkown
                                                               customer_id = travel-CustomerID
                                                               severity    = if_abap_behv_message=>severity-error )
                        %element-CustomerID = if_abap_behv=>mk-on ) to reported-travel.

      endif.


    endloop.

  endmethod.

  method validateDates.
  endmethod.

endclass.
