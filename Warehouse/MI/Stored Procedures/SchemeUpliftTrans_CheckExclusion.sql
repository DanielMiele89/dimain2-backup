-- =============================================
-- Author:		JEA
-- Create date: 24/03/2014
-- Description:	Verifies whether transactions in 
-- SchemeUpliftTrans would pass the live matching rules
--REWORK - original is MI.SchemeUpliftTrans_Stage_CheckExclusion
-- =============================================
CREATE PROCEDURE [MI].[SchemeUpliftTrans_CheckExclusion] 
	
AS
BEGIN
	
	SET NOCOUNT ON;

	DECLARE @MaxID INT, @StartID INT, @EndID INT, @Increment INT = 500000

	SELECT @MaxID = COUNT(1) FROM MI.SchemeUpliftTrans_Stage

	SET @StartID = 1
	SET @EndID = @Increment

	WHILE @StartID < @MaxID
	BEGIN

		UPDATE s set ExcludeNonTime = 0
		FROM MI.SchemeUpliftTrans_Stage s
		INNER JOIN
		(
			select
				n.FileID, 
				n.RowNum
			from mi.SchemeUpliftTrans_stage n
			inner join slc_report.dbo.RetailOutlet ro on n.OutletID = ro.ID
			inner join slc_report.dbo.[Partner] p on ro.PartnerID = p.ID
			inner join slc_report.dbo.IronOffer io
										on io.PartnerID = p.id
			where 
				n.ID BETWEEN @StartID AND @EndID AND
				n.FanID is not null and
				io.IsSignedOff = 1 --and 
		) u on s.fileid = u.fileid and s.rownum = u.rownum

		SET @StartID = @StartID + @Increment
		SET @EndID = @EndID + @Increment

	END

END
