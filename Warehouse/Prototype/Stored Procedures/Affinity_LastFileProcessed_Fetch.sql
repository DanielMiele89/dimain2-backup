-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [Prototype].[Affinity_LastFileProcessed_Fetch]
	
AS
BEGIN
	
	SET NOCOUNT ON;

	DECLARE @StartDate DATE
	
	SET @StartDate = DATEADD(MONTH,-1,DATEFROMPARTS(YEAR(GETDATE()),MONTH(GETDATE()),1))

    SELECT MAX(FileID) 
	FROM Relational.ConsumerTransaction WITH (NOLOCK)
	WHERE TranDate >= @StartDate

END
