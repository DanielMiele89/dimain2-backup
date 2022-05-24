CREATE TABLE [InsightArchive].[PowerBITest] (
    [ID]              INT     IDENTITY (1, 1) NOT NULL,
    [MonthDate]       DATE    NOT NULL,
    [IsOnline]        BIT     NOT NULL,
    [PartnerID]       INT     NOT NULL,
    [PaymentMethodID] TINYINT NOT NULL,
    [Spend]           MONEY   NOT NULL,
    [Rewards]         MONEY   NOT NULL,
    PRIMARY KEY CLUSTERED ([ID] ASC)
);

