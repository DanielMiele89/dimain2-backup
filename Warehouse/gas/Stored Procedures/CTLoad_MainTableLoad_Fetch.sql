-- =============================================
-- Author:		JEA
-- Create date: 16/04/2014
-- Description:	Returns day name
-- =============================================
CREATE PROCEDURE [gas].[CTLoad_MainTableLoad_Fetch]
	
AS
BEGIN

	SET NOCOUNT ON;

	DECLARE @DayName VARCHAR(50)

	SELECT @DayName = UPPER(DATENAME(DW, GETDATE()))

	SELECT CAST(CASE @DayName WHEN 'SATURDAY' THEN 1 WHEN 'SUNDAY' THEN 2 ELSE 0 END AS INT) AS MainTableLoadOrMIDI
	--select CAST(2 as int) as MainTableLoadOrMIDI

END