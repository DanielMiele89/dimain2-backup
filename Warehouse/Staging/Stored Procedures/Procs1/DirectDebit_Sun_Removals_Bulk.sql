/*

	Author:			Stuart Barnley

	Date:			1st September 2017

	Purpose:		To update a batch of OINs to stop them being incentvised

	Background:		RBSG have done some research and realised a set of OINs 
					are being incentivised Incorrectly, therefore they wish 
					them removed in batches in the 00s

*/
Create Procedure Staging.DirectDebit_Sun_Removals_Bulk
With Execute as Owner
As
-------------------------------------------------------------------------------
--------------------Pull list of SUNs/OINs that neede removing-----------------
-------------------------------------------------------------------------------

Select	OIN,
		ROW_NUMBER() OVER(ORDER BY OIN ASC) AS RowNo
Into #OINS
From Staging.RBSGRemovalsBulk as a
Where a.RemovalDate is null

Create Clustered Index cix_OINS_OIN on #OINS (OIN)

-------------------------------------------------------------------------------
---------------------------------Loop removal call-----------------------------
-------------------------------------------------------------------------------

Declare @RowNo int = 1,
		@RowNoMax int = (Select Max(RowNo) From #OINs),
		@OIN int

While @RowNo <= @RowNoMax
Begin
	   Set @OIN = (Select OIN from #OINS Where RowNo = @RowNo) -- Find OIN

	   Exec Staging.DirectDebit_Sun_Removals_1ofBulk @OIN -- Call Removal SP

	   Set @RowNo = @RowNo+1
End

-------------------------------------------------------------------------------
-------------------update the Staging.DirectDebit_EligibleOINs-----------------
-------------------------------------------------------------------------------

EXEC Staging.WarehouseLoad_DirectDebit_OINs