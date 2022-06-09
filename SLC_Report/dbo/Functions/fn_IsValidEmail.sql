
-- =============================================
-- Author: Unknown
-- Create date: Unknown
-- JIRA ticket: 
-- Description: Validates email address format
-- 
-- Change Log:
--				17/08/2015 - Nitin - LOYTWO-313, Second line of validation added.
--				19/08/2015 - Nitin - LOYTWO-313, special charaters validation added
--Modified Date: 2017-07-18; Modified By: H Knox; Jira Ticket:RBSFIX-83 Removed hyphens from restricted special characters list
				
-- =============================================
CREATE FUNCTION [dbo].[fn_IsValidEmail] (@Email nvarchar(100))
RETURNS bit
AS
BEGIN

	if @Email is null return 0

	if @Email not like '%@%.%' return 0

	if charindex('(', @Email) + charindex(')', @Email) + charindex(';', @Email) + charindex('>', @Email) + charindex('<', @Email) + charindex('+', @Email) + 
		charindex('/', @Email) + charindex(' ', @Email) + charindex(',', @Email) + charindex('=', @Email) > 0 return 0
			
	--LOYTWO-313	
	--two dots together not allowed, dot and @ together not allowed
	IF CHARINDEX('..', @Email) + CHARINDEX('.@', @Email) + CHARINDEX('@.', @Email) + CHARINDEX('@@', @Email) > 0 RETURN 0

	--multiple @ are not allowed
	IF @Email LIKE '%@%@%' RETURN 0

	--should not start/end with dot or @
	IF RIGHT(@Email, 1) IN ('.', '@') OR LEFT(@Email, 1) IN ('.', '@') RETURN 0

	--Check few more special characters
	IF	CHARINDEX('!', @Email) + CHARINDEX('"', @Email) + CHARINDEX('£', @Email) + CHARINDEX('$', @Email) + CHARINDEX('%', @Email) + CHARINDEX('^', @Email) + 
		CHARINDEX('&', @Email) + CHARINDEX('*', @Email) + CHARINDEX(':', @Email) + CHARINDEX('|', @Email) + CHARINDEX('\', @Email) +
		CHARINDEX('?', @Email) + CHARINDEX('¬', @Email) + CHARINDEX('`', @Email) + CHARINDEX('#', @Email) > 0 RETURN 0

--CHARINDEX('-', @Email) +

	return 1

END
