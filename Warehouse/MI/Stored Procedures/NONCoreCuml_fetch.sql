
-- =============================================
-- Author:		<Adam Scott>
-- Create date: <26/11/2014>
-- Description:	< returns Partnerid Clientservices>
-- =============================================
CREATE PROCEDURE [MI].[NONCoreCuml_fetch] (@Dateid int)
	-- Add the parameters for the stored procedure here

AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- Insert statements for procedure here
SELECT 
      [Cumlitivetype]
      ,[Partnerid]
      ,[ClientServicesref]
      ,[StartDate]
      ,[Dateid]
  FROM [MI].[WorkingCumlDates]
  where Dateid = @Dateid and ClientServicesref <>'0'
END