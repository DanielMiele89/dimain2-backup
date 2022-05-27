-- =============================================
-- Author:		AJS
-- Create date: 10/01/2014
-- Description:	Populates MI.ActiveOffersPartners_fetchNON 
-- =============================================
CREATE PROCEDURE [MI].[ActiveOffersPartners_fetchNONCore]

( @Monthid as int )
AS
BEGIN
	SET NOCOUNT ON;

delete from MI.ActiveOffersPartners_fetchNON 

insert into MI.ActiveOffersPartners_fetchNON 
	SELECT 
	  Ir.PartnerID, Min(IR.StartDate) as StartDate, MAX(IR.EndDate) as EndDate
  FROM  [Warehouse].[Relational].[IronOffer] IR
  inner join Warehouse.Relational.SchemeUpliftTrans_Month SUTM on SUTM.EndDate >= IR.StartDate and SUTM.StartDate <= IR.EndDate
  where SUTM.ID = @Monthid 
  and IR.IronOfferID not in  (1647, 1799) 
  group by 
  Ir.PartnerID

  end 