-- =============================================
-- Author:		JEA
-- Create date: 04/09/2013
-- Description:	Returns a list of dates associated
-- with the SchemeMID record
-- =============================================
CREATE PROCEDURE [MI].[SchemeMIDDates_List] 
	
AS
BEGIN
	
	SET NOCOUNT ON;

    SELECT s.OutletID
		, s.AddedDate
		, s.StartDate AS MIDStartDate
		, s.EndDate AS MIDEndDate
    FROM Relational.SchemeMID s
    
END