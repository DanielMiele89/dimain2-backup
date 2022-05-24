-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date, ,>
-- Description:	<Description, ,>
-- =============================================
CREATE FUNCTION [MI].[GetCharity] 
(
	@RedemptionDescription NVARCHAR(1000)
)
RETURNS VARCHAR(100)
AS
BEGIN

	DECLARE @i int, @CharityDescription NVARCHAR(1000), @CharityName VARCHAR(100)

	SELECT @i =  CHARINDEX('to', @RedemptionDescription,1)

	IF @i != 0
	BEGIN
		SET @CharityDescription = SUBSTRING(@RedemptionDescription, @i+3, LEN(@RedemptionDescription) - @i - 2)
	END
	ELSE
	BEGIN
		SET @CharityDescription = @RedemptionDescription
	END

	IF LEN(@CharityDescription) <= 50
	BEGIN
		SET @CharityName = CAST(@CharityDescription AS VARCHAR(50))
	END
	ELSE
	BEGIN
		SET @CharityName =  CAST(LEFT(@CharityDescription,100) AS VARCHAR(100))
	END

	RETURN @CharityName

END