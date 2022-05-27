-- =============================================
-- Author:		JEA
-- Create date: 25/11/2014
-- Description:	Retrieves archive data for retailer reports
-- =============================================
CREATE PROCEDURE MI.Retailer_ArchiveInfo
	(
		@PartnerID INT
		, @ClientServiceRef NVARCHAR(30)
		, @MonthID INT
		, @CumulativeTypeID INT
	)
AS
BEGIN
	
	SET NOCOUNT ON;

	SELECT m.MembersCardholders
			, m.MembersPostActivationSales
			, m.MembersPostActivationSpenders
			, m.MembersPostActivationTransactions
			, m.MembersSales
			, m.MembersSpenders
			, m.MembersTransactions
			, m.ControlCardHolders
			, m.Controlsales
			, m.ControlSpenders
			, m.ControlTransactions
			, m.AdjFactorRR
			, m.AdjFactorSPC
			, m.AdjFactorTPC
			, m.Margin
			, m.Commission
			, c.MembersCardholders AS MembersCardholdersCuml
			, c.MembersPostActivationSales AS MembersPostActivationSalesCuml
			, c.MembersPostActivationSpenders AS MembersPostActivationSpendersCuml
			, c.MembersPostActivationTransactions AS MembersPostActivationTransactionsCuml
			, c.MembersSales AS MembersSalesCuml
			, c.MembersSpenders AS MembersSpendersCuml
			, c.MembersTransactions AS MembersTransactionsCuml
			, c.ControlCardHolders AS ControlCardholdersCuml
			, c.Controlsales AS ControlSalesCuml
			, c.ControlSpenders AS ControlSpendersCuml
			, c.ControlTransactions AS ControlTransactionsCuml
			, c.AdjFactorRR AS AdjFactorRRCuml
			, c.AdjFactorSPC AS AdjFactorSPCCuml
			, c.AdjFactorTPC AS AdjFactorTPCCuml
			, c.Margin AS MarginCuml
			, c.Commission AS CommissionCuml
	FROM
	(
		SELECT m.MembersCardholders
			, m.MembersPostActivationSales
			, m.MembersPostActivationSpenders
			, m.MembersPostActivationTransactions
			, m.MembersSales
			, m.MembersSpenders
			, m.MembersTransactions
			, c.ControlCardHolders
			, c.Controlsales
			, c.ControlSpenders
			, c.ControlTransactions
			, c.AdjFactorRR
			, c.AdjFactorSPC
			, c.AdjFactorTPC
			, r.Margin
			, m.PartnerID
			, m.ClientServiceRef
			, r.Commission
		FROM MI.MemberssalesWorking m
		INNER JOIN MI.ControlSalesWorking c ON m.PartnerID = c.PartnerID AND m.ClientServiceRef = c.ClientServiceRef
		INNER JOIN (SELECT Margin, PartnerID, ClientServiceRef, Commission
					FROM MI.RetailerReportMetric
					WHERE PartnerID = @PartnerID
					AND ClientServiceRef = @ClientServiceRef
					AND DateID = @MonthID
					AND CumulativeTypeID = 0
					AND PaymentTypeID = 0
					AND ChannelID = 0 
					AND CustomerAttributeID = 0
					AND Mid_SplitID = 0 
					AND PeriodTypeID = 1) r ON m.PartnerID = r.PartnerID AND m.ClientServiceRef = r.ClientServiceRef
		WHERE m.PartnerID = @PartnerID
		AND m.ClientServiceRef = @ClientServiceRef
		AND m.DateID = @MonthID
		AND m.CumulativeTypeID = 0
		AND m.PaymentTypeID = 1 --NB: DEBIT
		AND m.ChannelID = 0 
		AND m.CustomerAttributeID = 0
		AND m.Mid_SplitID = 0 
		AND m.PeriodTypeID = 1
		AND c.DateID = @MonthID
		AND c.CumulativeTypeID = 0
		AND c.PaymentTypeID = 1 --NB: DEBIT
		AND c.ChannelID = 0 
		AND c.CustomerAttributeID = 0
		AND c.Mid_SplitID = 0 
		AND c.PeriodTypeID = 1
	) M
	INNER JOIN
	(
		SELECT m.MembersCardholders
			, m.MembersPostActivationSales
			, m.MembersPostActivationSpenders
			, m.MembersPostActivationTransactions
			, m.MembersSales
			, m.MembersSpenders
			, m.MembersTransactions
			, c.ControlCardHolders
			, c.Controlsales
			, c.ControlSpenders
			, c.ControlTransactions
			, c.AdjFactorRR
			, c.AdjFactorSPC
			, c.AdjFactorTPC
			, r.Margin
			, m.PartnerID
			, m.ClientServiceRef
			, r.Commission
		FROM MI.MemberssalesWorking m
		INNER JOIN MI.ControlSalesWorking c ON m.PartnerID = c.PartnerID AND m.ClientServiceRef = c.ClientServiceRef
		INNER JOIN (SELECT Margin, PartnerID, ClientServiceRef, Commission
					FROM MI.RetailerReportMetric
					WHERE PartnerID = @PartnerID
					AND ClientServiceRef = @ClientServiceRef
					AND DateID = @MonthID
					AND CumulativeTypeID = @CumulativeTypeID
					AND PaymentTypeID = 0
					AND ChannelID = 0 
					AND CustomerAttributeID = 0
					AND Mid_SplitID = 0 
					AND PeriodTypeID = 1) r ON m.PartnerID = r.PartnerID AND m.ClientServiceRef = r.ClientServiceRef
		WHERE m.PartnerID = @PartnerID
		AND m.ClientServiceRef = @ClientServiceRef
		AND m.DateID = @MonthID
		AND m.CumulativeTypeID = @CumulativeTypeID
		AND m.PaymentTypeID = 1 --NB: DEBIT
		AND m.ChannelID = 0 
		AND m.CustomerAttributeID = 0
		AND m.Mid_SplitID = 0 
		AND m.PeriodTypeID = 1
		AND c.DateID = @MonthID
		AND c.CumulativeTypeID = @CumulativeTypeID
		AND c.PaymentTypeID = 1 --NB: DEBIT
		AND c.ChannelID = 0 
		AND c.CustomerAttributeID = 0
		AND c.Mid_SplitID = 0 
		AND c.PeriodTypeID = 1
	) C ON M.PartnerID = c.PartnerID AND m.ClientServiceRef = c.ClientServiceRef


END
