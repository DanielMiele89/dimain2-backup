


	CREATE VIEW [dbo].[TrackingData]
	AS
	SELECT fanid, tracktypeid, trackdate, fandata, TrackingDataID, LoginTypeID, activitydata
	FROM SLC_Snapshot.dbo.TrackingData
