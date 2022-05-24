-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE prototype.Test1
	-- Add the parameters for the stored procedure here
AS
BEGIN 
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

IF OBJECT_ID('prototype.testBrands') IS NOT NULL DROP TABLE prototype.testBrands
select top 100 * 
into prototype.testBrands
from relational.brand

truncate table prototype.testBrands 

END
