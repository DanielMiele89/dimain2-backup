
/**********************************************************************

	Author:		 Hayden Reid
	Create date: 13/08/2015
	Description: Fetches monthly SPC results
***********************************************************************/
CREATE PROCEDURE [MI].[MonthlySPCHistory_Fetch]
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    select CASE WHEN m.ClientServiceRef <> '0' THEN p.PartnerName + ' ' + m.ClientServiceRef ELSE p.PartnerName END as PartnerName
	   , Controlsales
	   , ControlCardHolders
	   , MembersSales
	   , MembersCardholders
	   , AdjFactorSPC
	   , m.DateID
	   , sutm.MonthDesc 
    from mi.memberssalesworking m
    join mi.controlsalesworking c on c.PartnerID = m.PartnerID 
	   and c.clientserviceref = m.clientserviceref
	   AND c.CumulativeTypeID = m.CumulativeTypeID
	   AND c.PaymentTypeID = m.PaymentTypeID
	   AND c.ChannelID = m.ChannelID
	   AND c.CustomerAttributeID = m.CustomerAttributeID
	   AND c.Mid_SplitID = m.Mid_SplitID
	   AND c.PeriodTypeID = m.PeriodTypeID
	   AND c.DateID = m.DateID
    JOIN Relational.Partner p ON p.PartnerID = m.PartnerID
    JOIN Relational.SchemeUpliftTrans_Month sutm ON sutm.ID = m.DateID
    WHERE m.CumulativeTypeID = 0
	   and m.PaymentTypeID = 1
	   AND m.ChannelID = 0
	   AND m.CustomerAttributeID = 0
	   AND m.Mid_SplitID = 0
	   AND m.PeriodTypeID = 1
END