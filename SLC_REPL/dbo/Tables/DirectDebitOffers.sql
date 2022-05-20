CREATE TABLE [dbo].[DirectDebitOffers] (
    [IronOfferID]                       INT      NOT NULL,
    [EarnOnDDCount]                     INT      NOT NULL,
    [MaximumEarningsCount]              INT      NOT NULL,
    [MinimumFirstDDDelay]               INT      NOT NULL,
    [MaximumFirstDDDelay]               INT      NOT NULL,
    [MaximumEarningDDDelay]             INT      NOT NULL,
    [ActivationDays]                    INT      NOT NULL,
    [ApplyMinimumSpendToPending]        BIT      NOT NULL,
    [OfferType]                         CHAR (1) NOT NULL,
    [PriorTransThresholdCount]          INT      NOT NULL,
    [PriorTransThresholdFunction]       INT      NULL,
    [PriorTransThresholdDelay]          INT      NULL,
    [AggregateTransByDay]               BIT      NOT NULL,
    [InvalidateOfferOnEarlyTransaction] BIT      NOT NULL,
    CONSTRAINT [PK_DirectDebitOffers_IronOfferID] PRIMARY KEY CLUSTERED ([IronOfferID] ASC)
);


GO
GRANT SELECT
    ON OBJECT::[dbo].[DirectDebitOffers] TO [ProcessOp]
    AS [dbo];


GO
GRANT SELECT
    ON OBJECT::[dbo].[DirectDebitOffers] TO [virgin_etl_user]
    AS [dbo];

