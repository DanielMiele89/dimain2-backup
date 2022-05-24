
-- =============================================
-- Author:		<Adam Scott>
-- Create date: <26/11/2014>
-- Description:	<MI.OutletAttribute_load>
-- =============================================
CREATE PROCEDURE [MI].[OutletAttribute_load] (@dateid int, @PartnerID INT = NULL)
	WITH EXECUTE AS OWNER
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- Insert statements for procedure here
   --declare @dateid int 
   --set @Dateid=33
   
    Truncate Table MI.OutletAttribute


	insert into MI.OutletAttribute (ID, OutletID, ReportMID_SplitID, StartDate, EndDate, Mid_SplitID)
    SELECT st.ID, o.OutletID,d.ReportMID_SplitID, st.StartDate, St.EndDate,
    ISNULL(MAX(m.Mid_SplitID), d.Default_Mid_SplitID) as Mid_SplitID
    --INTO #outletattribute
    FROM Warehouse.Relational.SchemeMID o
    INNER JOIN (SELECT PartnerID, ReportMID_SplitID, MAX(CASE WHEN DefaultStatus=1 THEN Mid_SplitID END) Default_Mid_SplitID
		FROM Warehouse.MI.RetailerReportMID_Split
		WHERE (@PartnerID IS NULL OR PartnerID = @PartnerID)
		GROUP BY PartnerID, ReportMID_SplitID) d ON d.PartnerID=o.PartnerID
    CROSS JOIN (SELECT * FROM   Relational.SchemeUpliftTrans_Month st
    Where ST.ID between 20 and @DateID ) st 
    LEFT JOIN Warehouse.MI.ReportMID s  ON st.EndDate BETWEEN s.StartDate AND ISNULL(s.EndDate, st.EndDate) 
    AND s.OutletID=o.OutletID AND d.ReportMID_SplitID=s.SplitID
    LEFT JOIN Warehouse.MI.RetailerReportMID_Split m ON m.ReportMID_StatusTypeID=s.StatusTypeID And m.ReportMID_SplitID=s.SplitID
    AND m.PartnerID=s.PartnerID
    GROUP BY st.ID, o.OutletID,d.ReportMID_SplitID,  d.Default_Mid_SplitID, st.StartDate, St.EndDate

    ALTER INDEX ALL ON MI.OutletAttribute REBUILD
END

