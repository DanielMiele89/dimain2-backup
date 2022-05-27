/******************************************************************************
Author	  Jason Shipp
Created	  02/02/2018
Purpose	
	Fetch table of ALS segment types for moving to AllPublisherWarehouse

Modification History
******************************************************************************/

CREATE PROCEDURE [Staging].[ALS_Campaign_Cycle_Members_Fetch_Segment_Types]

AS
BEGIN

	SET NOCOUNT ON;

	SELECT
		sst.ID
		, sst.SuperSegmentName
	FROM nFI.Segmentation.ROC_Shopper_Segment_Super_Types sst

	/**************************************************************************
	Create table for storing results on AllPublisherWarehouse:

	CREATE TABLE Transform.ALS_Segment_Type
		(ID INT NOT NULL
		, SuperSegmentName VARCHAR(50)
		, CONSTRAINT PK_ALS_segment_Type PRIMARY KEY CLUSTERED (ID)
		)
	***************************************************************************/

END