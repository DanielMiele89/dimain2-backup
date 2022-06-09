CREATE VIEW dbo.NobleFanAttributes
AS
SELECT CompositeID, Primacy, AccountKey, IsJoint, ControlGroupNumber, IsControl, ReportGroup, TreatmentGroup, LaunchGroup, OriginalEmailPermission
	, OriginalDMPermission, EmailOriginallySupplied, CurrentEmailPermission, CurrentDMPermission, IsOmitted, MonthOfBirth, YearOfBirth
FROM SLC_Snapshot.dbo.NobleFanAttributes