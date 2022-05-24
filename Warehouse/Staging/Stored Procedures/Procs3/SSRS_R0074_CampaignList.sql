
-- ***************************************************************************
-- Author: Suraj Chahal
-- Create date: 16/10/2014
-- Description: Report to pull top level stats for offers going live that week
-- ***************************************************************************
CREATE PROCEDURE [Staging].[SSRS_R0074_CampaignList]
			
AS
BEGIN
	SET NOCOUNT ON;



if object_id('Staging.SSRS_R0074_CampaignList_Interim') is not null drop table Staging.SSRS_R0074_CampaignList_Interim

Create table Staging.SSRS_R0074_CampaignList_Interim (
		ClientServicesRef varchar(15),
		OfferID Int)

/**************************************************************************
**************Looping mailable audience from selection tables**************
**************************************************************************/
DECLARE @StartRow INT,
	@Qry NVARCHAR(MAX),
	@TableName VARCHAR(100)

SET @StartRow = 1

WHILE @StartRow <= (SELECT MAX(TableID) FROM Relational.NominatedOfferMember_TableNames)
BEGIN

SET @TableName = (SELECT TableName FROM Relational.NominatedOfferMember_TableNames WHERE TableID = @StartRow)

SET @Qry = '
INSERT INTO Staging.SSRS_R0074_CampaignList_Interim
SELECT	Distinct ClientServicesRef,
		OfferID
FROM '+ @TableName +' s
Inner join Warehouse.iron.NominatedOfferMember as iom
	on s.OfferID = iom.IronOfferID and s.CompositeID = iom.CompositeID
'
EXEC sp_ExecuteSQL @Qry

SET @StartRow = @StartRow+1

END

SELECT	Distinct 
		p.PartnerName,
		cl.ClientServicesRef,
		Cast(Case
				When cn.ClientServicesRef is null then i.IronOfferName
				Else cn.CampaignName
			End as Varchar(200)) as CampaignName
FROM Staging.SSRS_R0074_CampaignList_Interim as cl
inner join warehouse.relational.ironoffer as i
	on cl.OfferID = i.IronOfferID
inner join Warehouse.relational.partner as p
	on i.PartnerID = p.PartnerID
Left Outer join Warehouse.Relational.CBP_CampaignNames as cn
	on cl.ClientServicesRef = cn.ClientServicesRef
ORDER BY ClientServicesRef--,HTMID

/*************************

*************************/

END