
CREATE VIEW [Selections].[ROCShopperSegment_SeniorStaffAccounts]
AS

SELECT	[FanID]
   ,	[CompositeID]
   ,	[FirstName]
   ,	[LastName]
   ,	[Email]
FROM [Warehouse].[Selections].[PrioritisedCustomerAccounts]