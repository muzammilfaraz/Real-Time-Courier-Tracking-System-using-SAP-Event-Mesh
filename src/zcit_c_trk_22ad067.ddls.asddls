@EndUserText.label: 'Tracking Log - Projection'
@AccessControl.authorizationCheck: #NOT_REQUIRED
@Search.searchable: true
@Metadata.allowExtensions: true
define view entity ZCIT_C_TRK_22AD067
  as projection on ZCIT_I_TRK_22AD067
{
      @Search.defaultSearchElement: true
  key PackageId,
  
      @Search.defaultSearchElement: true
  key TrackingId,
      
      ScanLocation,
      EventDescription,
      ScanTimestamp,
      ScannedBy,

      /* Associations */
      _Package : redirected to parent ZCIT_C_PKG_22AD067
}
