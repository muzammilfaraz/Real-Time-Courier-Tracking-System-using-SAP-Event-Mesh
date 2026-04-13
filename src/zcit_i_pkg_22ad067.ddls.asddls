@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'Courier Package - Interface View'
define root view entity ZCIT_I_PKG_22AD067
  as select from zcit_pkg_22ad067 as Package
  composition [0..*] of ZCIT_I_TRK_22AD067 as _TrackingLogs
{
  key package_id            as PackageId,
      sender_name           as SenderName,
      receiver_name         as ReceiverName,
      destination_city      as DestinationCity,
      priority              as Priority,
      delivery_status       as DeliveryStatus,

      /* --- UI Color Logic: Delivery Status --- */
      case delivery_status
        when 'D' then 3 /* 3 = Green  (Delivered)  */
        when 'T' then 2 /* 2 = Yellow (In Transit) */
        when 'X' then 1 /* 1 = Red    (Delayed)    */
        when 'P' then 0 /* 0 = Grey   (Pending)    */
        else 0
      end                   as StatusCriticality,

      /* --- UI Color Logic: Priority --- */
      case priority
        when '1' then 1 /* 1 = Red    (High Priority) */
        when '2' then 2 /* 2 = Yellow (Med Priority)  */
        when '3' then 3 /* 3 = Green  (Low Priority)  */
        else 0
      end                   as PriorityCriticality,

      /* Admin Data */
      @Semantics.user.createdBy: true
      created_by            as CreatedBy,
      @Semantics.systemDateTime.createdAt: true
      created_at            as CreatedAt,
      @Semantics.user.lastChangedBy: true
      last_changed_by       as LastChangedBy,
      @Semantics.systemDateTime.lastChangedAt: true
      last_changed_at       as LastChangedAt,

      /* Public Associations */
      _TrackingLogs
}
