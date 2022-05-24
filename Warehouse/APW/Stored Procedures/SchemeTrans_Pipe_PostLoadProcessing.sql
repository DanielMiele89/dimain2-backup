-- =============================================
-- Author:		JEA
-- Create date: 21/06/2018
-- Description:	Set IsRetailerReport flag in Warehouse.APW.SchemeTrans_Pipe
-- =============================================
CREATE PROCEDURE [APW].[SchemeTrans_Pipe_PostLoadProcessing]
	WITH EXECUTE AS 'ProcessOp'
AS
BEGIN

	SET NOCOUNT ON;

	UPDATE p SET IsRetailerReport = 0
	FROM APW.SchemeTrans_Pipe p
	INNER JOIN SLC_Report.dbo.MatchSelfFundedTransaction m
		ON p.ID = m.MatchID
	WHERE IsRetailerReport = 1

END
