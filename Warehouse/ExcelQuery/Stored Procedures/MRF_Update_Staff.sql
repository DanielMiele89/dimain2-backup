-- =============================================
-- Author:Dorota
-- Create date:02/09/2015
-- Description:Master Retailer File Update Data
-- =============================================
CREATE PROCEDURE [ExcelQuery].[MRF_Update_Staff]
(@StaffID AS INT,@FirstName AS VARCHAR(50),@Surname AS VARCHAR(100), @Active AS BIT, 
@JobTitle	AS VARCHAR(50), @DeskTelephone AS VARCHAR(25) , @MobileTelephone AS VARCHAR(25), @ContactEmail AS VARCHAR(150))
AS
BEGIN
	SET NOCOUNT ON;
	UPDATE [Warehouse].[Staging].[Reward_StaffTable]
	SET JobTitle=@JobTitle, DeskTelephone=@DeskTelephone,MobileTelephone=@MobileTelephone, ContactEmail=@ContactEmail
	WHERE StaffID=@StaffID 	
END