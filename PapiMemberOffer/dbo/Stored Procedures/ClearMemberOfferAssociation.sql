-- =============================================
-- Author:		Rajshikha Jain
-- Create date: 2016-01-04
-- Description:	Truncate table MemberOfferAssociation
-- =============================================
CREATE PROCEDURE [dbo].[ClearMemberOfferAssociation]
WITH EXECUTE AS OWNER
AS
TRUNCATE TABLE MemberOfferAssociation


GO
GRANT EXECUTE
    ON OBJECT::[dbo].[ClearMemberOfferAssociation] TO [GAS]
    AS [dbo];

