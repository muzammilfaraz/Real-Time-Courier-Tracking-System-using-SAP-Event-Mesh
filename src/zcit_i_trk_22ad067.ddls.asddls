@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'Tracking Log - Interface View'
define view entity ZCIT_I_TRK_22AD067
  as select from zcit_trk_22ad067 as TrackingLog
  association to parent ZCIT_I_PKG_22AD067 as _Package 
    on $projection.PackageId = _Package.PackageId
{
  key package_id            as PackageId,
  key tracking_id           as TrackingId,
      
      scan_location         as ScanLocation,
      event_description     as EventDescription,
      
      @Semantics.systemDateTime.createdAt: true
      scan_timestamp        as ScanTimestamp,
      @Semantics.user.createdBy: true
      scanned_by            as ScannedBy,

      /* Public Associations */
      _Package
}
