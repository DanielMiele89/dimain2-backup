CREATE TABLE [InsightArchive].[AmazonCreditCardOffer_Earnings] (
    [FanID]      INT   NULL,
    [TotalSpent] MONEY NULL,
    [Rewards]    MONEY NULL
);


GO
CREATE CLUSTERED INDEX [cix_AmazonCreditCardOffer_Earnings_FanID]
    ON [InsightArchive].[AmazonCreditCardOffer_Earnings]([FanID] ASC);

