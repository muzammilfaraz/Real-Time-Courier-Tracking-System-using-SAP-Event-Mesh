" 1. BUFFER CLASS: Holds data temporarily before the final save
CLASS lcl_buffer DEFINITION.
  PUBLIC SECTION.
    CLASS-DATA: mt_pkg_create TYPE STANDARD TABLE OF zcit_pkg_22ad067,
                mt_pkg_update TYPE STANDARD TABLE OF zcit_pkg_22ad067,
                mt_pkg_delete TYPE STANDARD TABLE OF zcit_pkg_22ad067,
                mt_trk_create TYPE STANDARD TABLE OF zcit_trk_22ad067,
                mt_trk_update TYPE STANDARD TABLE OF zcit_trk_22ad067,
                mt_trk_delete TYPE STANDARD TABLE OF zcit_trk_22ad067.
ENDCLASS.

" 2. HANDLER CLASS DEFINITION (Header & Item)
CLASS lhc_Package DEFINITION INHERITING FROM cl_abap_behavior_handler.
  PRIVATE SECTION.
    METHODS get_instance_authorizations FOR INSTANCE AUTHORIZATION
      IMPORTING keys REQUEST requested_authorizations FOR Package RESULT result.

    METHODS create FOR MODIFY IMPORTING entities FOR CREATE Package.
    METHODS update FOR MODIFY IMPORTING entities FOR UPDATE Package.
    METHODS delete FOR MODIFY IMPORTING keys FOR DELETE Package.
    METHODS read FOR READ IMPORTING keys FOR READ Package RESULT result.
    METHODS lock FOR LOCK IMPORTING keys FOR LOCK Package.
    METHODS cba_TrackingLogs FOR MODIFY IMPORTING entities_cba FOR CREATE Package\_TrackingLogs.
ENDCLASS.

CLASS lhc_TrackingLog DEFINITION INHERITING FROM cl_abap_behavior_handler.
  PRIVATE SECTION.
    METHODS update FOR MODIFY IMPORTING entities FOR UPDATE TrackingLog.
    METHODS delete FOR MODIFY IMPORTING keys FOR DELETE TrackingLog.
    METHODS read FOR READ IMPORTING keys FOR READ TrackingLog RESULT result.
ENDCLASS.

" 3. HANDLER CLASS IMPLEMENTATION: Package (Header)
CLASS lhc_Package IMPLEMENTATION.

  METHOD get_instance_authorizations.
    LOOP AT keys INTO DATA(ls_key).
      APPEND VALUE #( PackageId = ls_key-PackageId
                      %update   = if_abap_behv=>auth-allowed
                      %delete   = if_abap_behv=>auth-allowed ) TO result.
    ENDLOOP.
  ENDMETHOD.

  METHOD create.
    DATA: lv_timestamp TYPE tzntstmpl.
    GET TIME STAMP FIELD lv_timestamp.

    LOOP AT entities INTO DATA(ls_entity).
      APPEND VALUE #(
        client           = sy-mandt
        package_id       = ls_entity-PackageId
        sender_name      = ls_entity-SenderName
        receiver_name    = ls_entity-ReceiverName
        destination_city = ls_entity-DestinationCity
        priority         = ls_entity-Priority
        delivery_status  = ls_entity-DeliveryStatus
        created_by       = sy-uname
        created_at       = lv_timestamp
      ) TO lcl_buffer=>mt_pkg_create.

      " The UI Receipt
      INSERT VALUE #( %cid = ls_entity-%cid PackageId = ls_entity-PackageId ) INTO TABLE mapped-package.
    ENDLOOP.
  ENDMETHOD.

  METHOD update.
    DATA: lv_timestamp TYPE tzntstmpl.
    GET TIME STAMP FIELD lv_timestamp.

    LOOP AT entities INTO DATA(ls_entity).
      SELECT SINGLE * FROM zcit_pkg_22ad067 WHERE package_id = @ls_entity-PackageId INTO @DATA(ls_db).
      IF sy-subrc = 0.
        IF ls_entity-%control-DeliveryStatus = if_abap_behv=>mk-on. ls_db-delivery_status = ls_entity-DeliveryStatus. ENDIF.
        IF ls_entity-%control-Priority = if_abap_behv=>mk-on. ls_db-priority = ls_entity-Priority. ENDIF.

        ls_db-last_changed_by = sy-uname.
        ls_db-last_changed_at = lv_timestamp.
        APPEND ls_db TO lcl_buffer=>mt_pkg_update.

        " --- THE SAP EVENT MESH TRIGGER ---
        " If the Delivery Status was updated, we fire the event to the cloud!
        IF ls_entity-%control-DeliveryStatus = if_abap_behv=>mk-on.
          RAISE ENTITY EVENT zcit_i_pkg_22ad067~PackageUpdated
            FROM VALUE #( ( PackageId = ls_entity-PackageId
                            %param    = VALUE #( DeliveryStatus = ls_entity-DeliveryStatus
                                                 ScanLocation   = 'System Status Update' ) ) ).
        ENDIF.
        " ----------------------------------
      ENDIF.
    ENDLOOP.
  ENDMETHOD.

  METHOD delete.
    LOOP AT keys INTO DATA(ls_key).
      APPEND VALUE #( package_id = ls_key-PackageId ) TO lcl_buffer=>mt_pkg_delete.
    ENDLOOP.
  ENDMETHOD.

  METHOD read.
    " Unmanaged read logic (simplified for tutorial)
  ENDMETHOD.
  METHOD lock.
  ENDMETHOD.

  METHOD cba_TrackingLogs.
    DATA: lv_timestamp TYPE tzntstmpl.
    GET TIME STAMP FIELD lv_timestamp.

    LOOP AT entities_cba INTO DATA(ls_cba).
      LOOP AT ls_cba-%target INTO DATA(ls_item).
        APPEND VALUE #(
          client            = sy-mandt
          package_id        = ls_cba-PackageId
          tracking_id       = ls_item-TrackingId
          scan_location     = ls_item-ScanLocation
          event_description = ls_item-EventDescription
          scan_timestamp    = lv_timestamp
          scanned_by        = sy-uname
        ) TO lcl_buffer=>mt_trk_create.

        INSERT VALUE #( %cid = ls_item-%cid PackageId = ls_cba-PackageId TrackingId = ls_item-TrackingId ) INTO TABLE mapped-trackinglog.
      ENDLOOP.
    ENDLOOP.
  ENDMETHOD.
ENDCLASS.

" 4. HANDLER CLASS IMPLEMENTATION: Tracking Log (Item)
CLASS lhc_TrackingLog IMPLEMENTATION.
  METHOD update.
    " Logic for updating logs
  ENDMETHOD.

  METHOD delete.
    LOOP AT keys INTO DATA(ls_key).
      APPEND VALUE #( package_id = ls_key-PackageId tracking_id = ls_key-TrackingId ) TO lcl_buffer=>mt_trk_delete.
    ENDLOOP.
  ENDMETHOD.

  METHOD read.
  ENDMETHOD.
ENDCLASS.

" 5. SAVER CLASS: The final commit to the Database!
CLASS lsc_ZCIT_I_PKG_22AD067 DEFINITION INHERITING FROM cl_abap_behavior_saver.
  PROTECTED SECTION.
    METHODS save REDEFINITION.
    METHODS cleanup REDEFINITION.
ENDCLASS.

CLASS lsc_ZCIT_I_PKG_22AD067 IMPLEMENTATION.
  METHOD save.
    " Header DB Commits
    IF lcl_buffer=>mt_pkg_create IS NOT INITIAL. INSERT zcit_pkg_22ad067 FROM TABLE @lcl_buffer=>mt_pkg_create. ENDIF.
    IF lcl_buffer=>mt_pkg_update IS NOT INITIAL. UPDATE zcit_pkg_22ad067 FROM TABLE @lcl_buffer=>mt_pkg_update. ENDIF.
    IF lcl_buffer=>mt_pkg_delete IS NOT INITIAL.
      DELETE zcit_pkg_22ad067 FROM TABLE @lcl_buffer=>mt_pkg_delete.
      DELETE zcit_trk_22ad067 FROM TABLE @lcl_buffer=>mt_pkg_delete. " Delete child logs if package is deleted
    ENDIF.

    " Item DB Commits
    IF lcl_buffer=>mt_trk_create IS NOT INITIAL. INSERT zcit_trk_22ad067 FROM TABLE @lcl_buffer=>mt_trk_create. ENDIF.
    IF lcl_buffer=>mt_trk_delete IS NOT INITIAL. DELETE zcit_trk_22ad067 FROM TABLE @lcl_buffer=>mt_trk_delete. ENDIF.
  ENDMETHOD.

  METHOD cleanup.
    CLEAR: lcl_buffer=>mt_pkg_create, lcl_buffer=>mt_pkg_update, lcl_buffer=>mt_pkg_delete,
           lcl_buffer=>mt_trk_create, lcl_buffer=>mt_trk_update, lcl_buffer=>mt_trk_delete.
  ENDMETHOD.
ENDCLASS.
