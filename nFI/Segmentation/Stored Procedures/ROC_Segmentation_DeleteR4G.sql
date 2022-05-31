/*

	Author:		Stuart Barnley

	Date:		31st August 2017

	Purpose:	Delete from Segment Membership table where Customer is a member of R4G

*/

CREATE Procedure [Segmentation].[ROC_Segmentation_DeleteR4G]
As

----------------------------------------------------------------------------------------
---------------------------Find a distinct List of Customers----------------------------
----------------------------------------------------------------------------------------
IF OBJECT_ID('tempdb..#R4GMembers') IS NOT NULL DROP TABLE #R4GMembers
Select Distinct f.ID as FanID
Into #R4GMembers
From Warehouse.InsightArchive.QuidcoR4GCustomers as R4G
inner join slc_report.dbo.Fan as f
	on R4G.CompositeID = f.CompositeID

----------------------------------------------------------------------------------------
---------------------------Delete the R4G Segmentation entries--------------------------
----------------------------------------------------------------------------------------
Delete a
--Select Count(*),Count(Distinct a.FanID)
from [Segmentation].[ROC_Shopper_Segment_Members] as a
inner join #R4GMembers as r
	on a.FanID = r.FanID

