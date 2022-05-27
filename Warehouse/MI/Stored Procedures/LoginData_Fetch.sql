-- =============================================
-- Author:		JEA
-- Create date: 30/07/2018
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [MI].[LoginData_Fetch]
	
AS
BEGIN

	SET NOCOUNT ON;

	SELECT Gender
		, Age
		, PostCode
		, PostCodeDistrict
		, LoginDate
		, TimeDesc
		, BookType
		, AccountType
		, LoginWeekDay
	FROM MI.LoginInfo

END