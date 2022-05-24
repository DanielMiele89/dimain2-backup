-- =============================================
-- Author:		<Adam Scott>
-- Create date: <26/03/2014>
-- Description:	<gets Offers promoted>
-- =============================================
CREATE PROCEDURE [MI].[CampaingnPreformance_EmailPromtedOffers_Fetch]
	WITH EXECUTE AS OWNER
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- Insert statements for procedure here
DECLARE   @StartDate date 
		, @ThisMonthStart DATE
		, @ThisMonthEnd DATE
		, @LastMonthStart DATE


		set   @StartDate = 'Aug 01, 2012'
		--First day of the lag date month
		SET @ThisMonthEnd = CONVERT(VARCHAR(25),DATEADD(dd,-(DAY(GETDATE())-1),GETDATE()),101)
		
		--First day of the previous (i.e. completed) month
		SET @ThisMonthStart = DATEADD(MONTH, -1, @ThisMonthEnd)
		--last day of that month
		SET @ThisMonthEnd = DATEADD(DAY, -1, @ThisMonthEnd)
		SET @LastMonthStart = DATEADD(MONTH, -1, @ThisMonthStart)

 
drop table MI.Last2Months_temp
Select	SendDate
into	MI.Last2Months_temp
from
(Select	cast(datename(month,senddate) + ' 01, ' + cast(YEAR(senddate) as varchar(4)) as DATe) as SendDate--,

from
(select	ec.CampaignKey,ec.senddate,ec.CampaignName
from SLC_Report.dbo.EmailCampaign as ec
Where	ec.senddate  >= @StartDate and
		ec.SendDate  <  dateadd(day,1,@ThisMonthEnd)
Group by ec.CampaignKey,
ec.senddate,ec.CampaignName
) as a
Group by cast(datename(month,senddate) + ' 01, ' + cast(YEAR(senddate) as varchar(4)) as DATe)
) as a
Group by SendDate
having SendDate between @LastMonthStart and @ThisMonthEnd 
order by SendDate

Select	SendDate,
		Count(ClientServicesRef) as OffersPromoted,
		
		Sum(Case
				When AboveBase > 0 then 1
				Else 0
			End) as AboveBaseOffers,
		Sum(Case
				When AboveBase = 0 then 1
				Else 0
			End) as BaseOffers
from	

(select m.SendDate, 
		Case
			When i.ClientServicesRef IS not null then i.ClientServicesRef
			Else 'XB-'+cast(base.PartnerID as CHAR(4)) + '-'+ cast(datepart(Year,base.StartDate) as CHAR(4))+ '-'+cast(datepart(month,base.StartDate) as CHAR(2))
		End as ClientServicesRef,
		Max(Case
				When i.AboveBase IS not null then i.AboveBase
				Else 0
			End) as AboveBase
 from MI.Last2Months_temp as m
inner join SLC_Report.dbo.EmailCampaign as ec
	on ec.SendDate >= m.SendDate and ec.SendDate < dateadd(month,1,m.SendDate)
inner join warehouse.Relational.CampaignLionSendIDs as cls
	on ec.CampaignKey = cls.CampaignKey
inner join SLC_Report.lion.LionSendComponent as lsc
	on cls.LionSendID = lsc.LionSendID
Left Outer join warehouse.relational.IronOffer_Campaign_HTM as i	
	on lsc.ItemID = i.Ironofferid
inner join Warehouse.relational.IronOffer as Base
	on lsc.ItemID = Base.IronOfferID
	
Group by m.SendDate, 
		Case
			When i.ClientServicesRef IS not null then i.ClientServicesRef
			Else 
				'XB-'+cast(base.PartnerID as CHAR(4)) + '-'+ cast(datepart(Year,base.StartDate) as CHAR(4))+ '-'+cast(datepart(month,base.StartDate) as CHAR(2))
		End
) as a
Group by SendDate
order by SendDate

END
