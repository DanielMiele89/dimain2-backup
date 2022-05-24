-- =============================================
-- Author: JEA
-- Create date: 07/06/2016
-- Description:	Returns parameters for the monthly retailer report automatic file generation
-- =============================================
CREATE PROCEDURE [APW].[RetailerReportParamsNew_Fetch] 

AS
BEGIN
	
	SET NOCOUNT ON;

	DECLARE @MonthDate date = DATEADD(MONTH, -1, DATEFROMPARTS(YEAR(GETDATE()), MONTH(GETDATE()), 1));

	IF (SELECT GETDATE()) < '2022-05-17' SET @MonthDate = DATEADD(MONTH, -1, @MonthDate)

	DECLARE @MonthName VARCHAR(50) = DATENAME(MONTH, @MonthDate) + CAST(YEAR(@MonthDate) AS VARCHAR(4));
	
	SELECT 
		r.PartnerID
		, r.PartnerName
		, @MonthName AS MonthDesc 
	FROM APW.ControlRetailers r
	--WHERE r.PartnerID IN (
	--4724
	--);

END