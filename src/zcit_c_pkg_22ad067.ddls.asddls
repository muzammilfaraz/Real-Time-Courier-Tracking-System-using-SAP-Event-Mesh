@EndUserText.label: 'Courier Package - Projection'
@AccessControl.authorizationCheck: #NOT_REQUIRED
@Search.searchable: true
@Metadata.allowExtensions: true
define root view entity ZCIT_C_PKG_22AD067
  provider contract transactional_query
  as projection on ZCIT_I_PKG_22AD067
{
      @Search.defaultSearchElement: true
  key PackageId,
  
      @Search.defaultSearchElement: true
      SenderName,
      
      @Search.defaultSearchElement: true
      ReceiverName,
      
      DestinationCity,
      Priority,
      DeliveryStatus,

      /* --- Bring our Color Logic to the UI layer --- */
      StatusCriticality,
      PriorityCriticality,
      /* --------------------------------------------- */

      CreatedBy,
      CreatedAt,
      LastChangedBy,
      LastChangedAt,

      /* Associations */
      _TrackingLogs : redirected to composition child ZCIT_C_TRK_22AD067
}
