-- =============================================
-- Author:Dorota
-- Create date:02/09/2015
-- Description:Master Retailer File Upload Data
-- =============================================
CREATE PROCEDURE [ExcelQuery].[MRF_Fetch_Staff]
AS
BEGIN
	SET NOCOUNT ON;
	SELECT StaffID,	FirstName,	Surname,	CAST(Active AS	INT), JobTitle,	
	DeskTelephone,	MobileTelephone,	ContactEmail,
	CONCAT(FirstName,' ',Surname) Person
     FROM Warehouse.Staging.Reward_StaffTable
END