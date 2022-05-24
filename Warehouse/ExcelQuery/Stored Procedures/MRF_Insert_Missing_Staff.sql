-- =============================================
-- Author:Dorota
-- Create date:02/09/2015
-- Description:Master Retailer File Insert Missing Data
-- =============================================

CREATE PROCEDURE [ExcelQuery].[MRF_Insert_Missing_Staff]
(@FirstName AS VARCHAR(50),@Surname AS VARCHAR(100), @Active AS BIT, 
@JobTitle	AS VARCHAR(50), @DeskTelephone AS VARCHAR(25) , @MobileTelephone AS VARCHAR(25), @ContactEmail AS VARCHAR(150))
AS
BEGIN
	SET NOCOUNT ON;
	INSERT INTO ExcelQuery.MRF_Missing_Staff
	SELECT @FirstName,@Surname, @Active, @JobTitle, @DeskTelephone,@MobileTelephone,@ContactEmail
END